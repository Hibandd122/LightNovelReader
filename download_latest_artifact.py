import os
import sys
import json
import zipfile
import io
import shutil
from pathlib import Path
from datetime import datetime, timezone, timedelta

import requests

ARTIFACT_NAME = "GoogleDocsTTS-Dylib"
REPO = "Hibandd122/LightNovelReader"
OUTPUT_DYLIB = "GoogleDocsTTS.dylib"


def get_token():
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if not token:
        token_file = Path(__file__).parent / ".gh_token"
        if token_file.exists():
            token = token_file.read_text(encoding="utf-8").strip()
    if not token:
        print("[-] No GitHub token found. Set GH_TOKEN env var or create a .gh_token file.")
        sys.exit(1)
    return token


def main():
    token = get_token()
    api_url = f"https://api.github.com/repos/{REPO}/actions/artifacts"
    headers = {"Authorization": f"token {token}", "Accept": "application/vnd.github+json"}

    print("[+] Fetching artifacts list...")
    response = requests.get(api_url, headers=headers, timeout=30)
    if response.status_code == 401:
        print("[-] Authentication failed. Check your token.")
        sys.exit(1)
    response.raise_for_status()

    data = response.json()
    artifacts = [a for a in data.get("artifacts", []) if a["name"] == ARTIFACT_NAME]
    if not artifacts:
        print(f"[-] No artifacts found named {ARTIFACT_NAME}.")
        sys.exit(1)

    latest = sorted(artifacts, key=lambda a: a["created_at"], reverse=True)[0]
    created = datetime.strptime(latest["created_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
    age = datetime.now(timezone.utc) - created
    print(f"[+] Latest artifact created {age.total_seconds() / 60:.1f} min ago")
    if age > timedelta(minutes=30):
        print("[-] Artifact is older than 30 min - the latest build may have failed.")
        sys.exit(1)

    print(f"[+] Downloading artifact from {latest['archive_download_url']} ...")
    dl = requests.get(latest["archive_download_url"], headers=headers, timeout=120)
    dl.raise_for_status()

    with zipfile.ZipFile(io.BytesIO(dl.content)) as z:
        names = z.namelist()
        print(f"[+] Archive contents: {names}")
        if not names:
            print("[-] Artifact archive is empty.")
            sys.exit(1)
        with z.open(names[0]) as src, open(OUTPUT_DYLIB, "wb") as dst:
            shutil.copyfileobj(src, dst)

    print(f"[+] Saved {OUTPUT_DYLIB} ({os.path.getsize(OUTPUT_DYLIB)} bytes)")


if __name__ == "__main__":
    main()
