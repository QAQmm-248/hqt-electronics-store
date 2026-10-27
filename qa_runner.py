import json
import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

WORKSPACE = Path("/workspace")

class Handler(BaseHTTPRequestHandler):
    def reply(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self.reply(200, {"status": "ok", "workspace": WORKSPACE.is_dir()})
        else:
            self.reply(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/run-tests":
            self.reply(404, {"error": "not found"})
            return
        try:
            env = os.environ.copy()
            env['PYTHONPATH'] = str(WORKSPACE) + os.pathsep + env.get('PYTHONPATH', '')
            result = subprocess.run(
                [sys.executable, "-m", "pytest", "-q"],
                cwd=WORKSPACE,
                capture_output=True,
                text=True,
                env=env,
                timeout=120,
            )
            self.reply(200, {
                "exitCode": result.returncode,
                "passed": result.returncode == 0,
                "stdout": result.stdout[-12000:],
                "stderr": result.stderr[-4000:],
            })
        except subprocess.TimeoutExpired:
            self.reply(200, {"exitCode": 124, "passed": False, "error": "pytest timed out after 120 seconds"})
        except Exception as exc:
            self.reply(500, {"exitCode": 1, "passed": False, "error": str(exc)})

    def log_message(self, fmt, *args):
        print("%s - %s" % (self.address_string(), fmt % args), flush=True)

ThreadingHTTPServer(("0.0.0.0", 8080), Handler).serve_forever()


