from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, quote, urlparse
from urllib.request import Request, urlopen


ROOT = Path(__file__).resolve().parent / "dist"


class SpaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/tts":
            self.serve_tts(parse_qs(parsed.query).get("text", [""])[0])
            return
        path = Path(urlparse(self.path).path.lstrip("/"))
        requested = ROOT / path
        if not requested.exists() and "." not in path.name:
            self.path = "/index.html"
        super().do_GET()

    def serve_tts(self, text):
        if not text:
            self.send_error(400, "Missing text")
            return
        request_url = (
            "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=vi&q="
            + quote(text)
        )
        try:
            request = Request(request_url, headers={"User-Agent": "Mozilla/5.0"})
            with urlopen(request, timeout=20) as response:
                audio = response.read()
            self.send_response(200)
            self.send_header("Content-Type", "audio/mpeg")
            self.send_header("Content-Length", str(len(audio)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(audio)
        except Exception as error:
            self.send_error(502, f"Google TTS unavailable: {error}")


if __name__ == "__main__":
    server = ThreadingHTTPServer(("127.0.0.1", 5173), SpaHandler)
    print("LightNovel Reader: http://localhost:5173")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
