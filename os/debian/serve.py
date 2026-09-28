# Run this from the same folder as preseed.cfg, or pass the folder as an argument.
# Works on Windows, macOS and Linux (needs python3).

# Usage:
# python3 serve.py
# python3 serve.py path/to/preseed.cfg/folder

import http.server
import os
import socket
import sys

folder = sys.argv[1] if len(sys.argv) > 1 else "."
os.chdir(folder)

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
ip = s.getsockname()[0]
s.close()

print("Boot line:")
print(f"auto=true priority=high hostname=k-nas url=http://{ip}:8000/preseed.cfg")
print()
print(f"Serving {folder} on port 8000. Ctrl+C to stop once the install starts.")
print()

http.server.test(HandlerClass=http.server.SimpleHTTPRequestHandler, port=8000)