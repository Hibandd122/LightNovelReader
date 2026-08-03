import argparse
import os
import plistlib
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path

import lief

DEFAULT_IPA = "com.google.Docs.ipa"
DEFAULT_DYLIB = "GoogleDocsTTS.dylib"
DEFAULT_OUTPUT = "com.google.Docs.patched.ipa"
TEMP_ROOT = Path(r"C:\Users\hican\AppData\Local\Temp\opencode")


def find_app_dir(payload: Path):
    if not payload.is_dir():
        return None
    for entry in payload.iterdir():
        if entry.is_dir() and entry.suffix.lower() == ".app":
            return entry
    return None


def main_binary_name(app_dir: Path) -> str:
    info_path = app_dir / "Info.plist"
    if info_path.exists():
        try:
            with open(info_path, "rb") as f:
                info = plistlib.load(f)
            if "CFBundleExecutable" in info:
                return info["CFBundleExecutable"]
        except Exception:
            pass
    return app_dir.stem


def patch_binary(binary_path: Path, dylib_path: Path) -> list:
    load_name = f"@executable_path/Frameworks/{dylib_path.name}"
    fat = lief.MachO.parse(str(binary_path))
    if fat is None:
        raise RuntimeError(f"Could not parse Mach-O: {binary_path}")

    binaries = list(fat) if isinstance(fat, lief.MachO.FatBinary) else [fat]
    patched = []
    for b in binaries:
        existing = [c.name for c in b.commands if isinstance(c, lief.MachO.DylibCommand)]
        if load_name in existing:
            patched.append(f"already present ({b.header.cpu_type})")
            continue
        cmd = lief.MachO.DylibCommand.load_dylib(load_name)
        b.add(cmd)
        patched.append(f"injected ({b.header.cpu_type})")

    tmp_out = binary_path.with_suffix(binary_path.suffix + ".injected")
    fat.write(str(tmp_out))
    tmp_out.replace(binary_path)
    return patched


def repack(output_ipa: Path, payload: Path):
    if output_ipa.exists():
        output_ipa.unlink()
    with zipfile.ZipFile(output_ipa, "w", zipfile.ZIP_DEFLATED) as z:
        base = payload.parent
        for root, dirs, files in os.walk(payload):
            for name in files:
                full = Path(root) / name
                arc = str(full.relative_to(base))
                z.write(full, arc)


def verify(output_ipa: Path, dylib_name: str):
    load_name = f"@executable_path/Frameworks/{dylib_name}"
    with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as td:
        with zipfile.ZipFile(output_ipa) as z:
            z.extractall(td)
        payload = Path(td) / "Payload"
        app_dir = find_app_dir(payload)
        binary = app_dir / main_binary_name(app_dir)
        fat = lief.MachO.parse(str(binary))
        binaries = list(fat) if isinstance(fat, lief.MachO.FatBinary) else [fat]
        print("[+] Verification:")
        ok = True
        for b in binaries:
            names = [c.name for c in b.commands if isinstance(c, lief.MachO.DylibCommand)]
            if load_name in names:
                print(f"    LC_LOAD_DYLIB {load_name} -> present ({b.header.cpu_type})")
            else:
                print(f"    LC_LOAD_DYLIB {load_name} -> MISSING ({b.header.cpu_type})")
                ok = False
        lib_path = app_dir / "Frameworks" / dylib_name
        if lib_path.exists():
            print(f"    dylib in Frameworks -> {lib_path.name} ({lib_path.stat().st_size} bytes)")
        else:
            print("    dylib in Frameworks -> MISSING")
            ok = False
        return ok


def main():
    parser = argparse.ArgumentParser(description="Inject a dylib into an iOS IPA (Mach-O LC_LOAD_DYLIB).")
    parser.add_argument("--ipa", default=DEFAULT_IPA, help="Path to original IPA")
    parser.add_argument("--dylib", default=DEFAULT_DYLIB, help="Path to dylib to inject")
    parser.add_argument("--output", default=DEFAULT_OUTPUT, help="Output IPA path")
    parser.add_argument("--verify-only", action="store_true", help="Only verify an existing patched IPA")
    args = parser.parse_args()

    ipa = Path(args.ipa)
    dylib = Path(args.dylib)
    output = Path(args.output)

    if args.verify_only:
        ok = verify(output, dylib.name)
        sys.exit(0 if ok else 1)

    if not ipa.exists():
        print(f"[-] IPA not found: {ipa}")
        sys.exit(1)
    if not dylib.exists():
        print(f"[-] Dylib not found: {dylib}")
        sys.exit(1)

    print(f"[+] Source IPA : {ipa}")
    print(f"[+] Dylib      : {dylib}")
    print(f"[+] Output IPA : {output}")

    with tempfile.TemporaryDirectory(dir=TEMP_ROOT) as td:
        work = Path(td)
        extract_dir = work / "extract"
        extract_dir.mkdir()

        print("[+] Extracting IPA...")
        with zipfile.ZipFile(ipa) as z:
            z.extractall(extract_dir)

        payload = extract_dir / "Payload"
        app_dir = find_app_dir(payload)
        if app_dir is None:
            print("[-] No .app found under Payload/")
            sys.exit(1)
        print(f"[+] App bundle : {app_dir.name}")

        frameworks = app_dir / "Frameworks"
        frameworks.mkdir(exist_ok=True)
        dest_dylib = frameworks / dylib.name
        shutil.copy2(dylib, dest_dylib)
        print(f"[+] Copied {dylib.name} -> Frameworks/{dylib.name}")

        binary = app_dir / main_binary_name(app_dir)
        print(f"[+] Main binary: {binary.name}")
        results = patch_binary(binary, dylib)
        for r in results:
            print(f"[+] {r}")

        # Remove stale signature so sideload tools re-sign cleanly.
        for stale in (app_dir / "_CodeSignature", app_dir / "SC_Info"):
            if stale.exists():
                shutil.rmtree(stale, ignore_errors=True)
                print(f"[+] Removed {stale.name} (will be re-signed on install)")

        print(f"[+] Repacking IPA -> {output} ...")
        repack(output, payload)

    print("[+] Done. Verifying...")
    ok = verify(output, dylib.name)
    if ok:
        print("[+] All checks passed.")
        sys.exit(0)
    else:
        print("[-] Verification failed.")
        sys.exit(1)


if __name__ == "__main__":
    main()
