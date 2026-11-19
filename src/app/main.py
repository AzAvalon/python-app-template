"""Application entry point.

Put the application here. Until then it only answers the Kubernetes
probes: GET /healthz returns 200 on port APP_PORT (default 8000).
"""

import logging
import os
import signal
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

logger = logging.getLogger(__name__)


class HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        if self.path == "/healthz":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        else:
            self.send_error(404)

    def log_message(self, format: str, *args: object) -> None:
        # Probes hit /healthz every few seconds: keep them out of the logs.
        pass


def main() -> None:
    logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"))
    port = int(os.environ.get("APP_PORT", "8000"))
    server = ThreadingHTTPServer(("0.0.0.0", port), HealthHandler)  # noqa: S104
    # Kubernetes stops pods with SIGTERM: shut down cleanly. shutdown() waits
    # for serve_forever() to return, so it must run on another thread.
    signal.signal(signal.SIGTERM, lambda *_: threading.Thread(target=server.shutdown).start())
    logger.info("listening on port %d", port)
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
