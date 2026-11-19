import threading
import urllib.request
from http.server import ThreadingHTTPServer

from app.main import HealthHandler


def test_healthz() -> None:
    server = ThreadingHTTPServer(("127.0.0.1", 0), HealthHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        url = f"http://127.0.0.1:{server.server_port}/healthz"
        with urllib.request.urlopen(url, timeout=5) as response:  # noqa: S310
            assert response.status == 200
    finally:
        server.shutdown()
        server.server_close()
