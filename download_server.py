import http.server
import socketserver
import socket
import sys
import os
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')
PORT = 8080
DIRECTORY = Path(__file__).parent.resolve()

class DownloadHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(DIRECTORY), **kwargs)

    def do_GET(self):
        if self.path == "/" or self.path == "/index.html":
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            
            ipa_size = 0
            patched_ipa = DIRECTORY / "com.google.Docs.patched.ipa"
            if patched_ipa.exists():
                ipa_size = patched_ipa.stat().st_size / (1024 * 1024)

            html = f"""<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>IPA Download Center</title>
    <style>
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f172a; color: #f8fafc; text-align: center; padding: 2rem 1rem; }}
        .card {{ background: #1e293b; border-radius: 1rem; padding: 2rem; max-width: 500px; margin: 0 auto; box-shadow: 0 10px 25px rgba(0,0,0,0.5); border: 1px solid #334155; }}
        h1 {{ color: #38bdf8; font-size: 1.6rem; margin-bottom: 0.5rem; }}
        p {{ color: #94a3b8; font-size: 0.95rem; }}
        .btn {{ display: block; background: #0284c7; color: white; text-decoration: none; padding: 1rem 1.5rem; border-radius: 0.75rem; font-weight: bold; font-size: 1.1rem; margin: 1.5rem 0; box-shadow: 0 4px 12px rgba(2, 132, 199, 0.4); }}
        .btn:active {{ transform: scale(0.98); }}
        .meta {{ font-size: 0.85rem; color: #64748b; margin-bottom: 1.5rem; }}
        .file-list {{ text-align: left; border-top: 1px solid #334155; padding-top: 1rem; }}
        .file-item {{ display: flex; justify-content: space-between; align-items: center; padding: 0.75rem 0; border-bottom: 1px solid #1e293b; font-size: 0.9rem; }}
        .file-item a {{ color: #38bdf8; text-decoration: none; font-weight: 500; background: #0f172a; padding: 0.4rem 0.8rem; border-radius: 0.4rem; border: 1px solid #334155; }}
    </style>
</head>
<body>
    <div class="card">
        <h1>📱 IPA DOWNLOAD SERVER</h1>
        <p>Google Docs đã tiêm Dylib TTS (Hỗ trợ DOCX & Tốc độ đọc)</p>
        
        <a class="btn" href="/com.google.Docs.patched.ipa" download>⬇️ TẢI FILE IPA ({ipa_size:.1f} MB)</a>
        <div class="meta">✅ Đã kiểm tra Mach-O Header & LC_LOAD_DYLIB Injection</div>
        
        <div class="file-list">
            <div class="file-item">
                <div>
                    <strong>com.google.Docs.patched.ipa</strong><br>
                    <small style="color:#64748b;">IPA đã vá Dylib UI</small>
                </div>
                <a href="/com.google.Docs.patched.ipa" download>Tải về</a>
            </div>
            <div class="file-item">
                <div>
                    <strong>com.google.Docs.ipa</strong><br>
                    <small style="color:#64748b;">IPA gốc</small>
                </div>
                <a href="/com.google.Docs.ipa" download>Tải về</a>
            </div>
            <div class="file-item">
                <div>
                    <strong>InjectedTTS.mm</strong><br>
                    <small style="color:#64748b;">Objective-C Code</small>
                </div>
                <a href="/InjectedTTS.mm">Xem mã</a>
            </div>
        </div>
    </div>
</body>
</html>"""
            self.wfile.write(html.encode("utf-8"))
            return
        super().do_GET()

def get_local_ips():
    ips = []
    try:
        hostname = socket.gethostname()
        for ip in socket.gethostbyname_ex(hostname)[2]:
            if not ip.startswith("127."):
                ips.append(ip)
    except Exception:
        pass
    return ips

class ThreadedTCPServer(socketserver.ThreadingMixIn, socketserver.TCPServer):
    allow_reuse_address = True

if __name__ == "__main__":
    ips = get_local_ips()
    print("=" * 60)
    print(f"[+] SERVER ONLINE PORT {PORT}")
    print("[+] Truy cap tu dien thoai theo cac dia chi IP sau:")
    for ip in ips:
        print(f"    --> http://{ip}:{PORT}")
    print(f"    --> http://localhost:{PORT}")
    print("=" * 60)
    
    with ThreadedTCPServer(("0.0.0.0", PORT), DownloadHTTPRequestHandler) as httpd:
        httpd.serve_forever()
