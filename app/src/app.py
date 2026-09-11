from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import os


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, body, content_type="application/json"):
        encoded = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)

    def do_GET(self):
        if self.path in ("/", "/healthz", "/readyz"):
            environment = os.getenv("ENVIRONMENT", "unknown")
            version = os.getenv("APP_VERSION", "dev")
            payload = {
                "service": "gitops-demo",
                "environment": environment,
                "version": version,
                "status": "ok",
            }
            self._send(200, json.dumps(payload))
            return

        self._send(404, json.dumps({"error": "not found"}))

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args))


def main():
    port = int(os.getenv("PORT", "8080"))
    server = HTTPServer(("0.0.0.0", port), Handler)
    print(f"gitops-demo listening on :{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
