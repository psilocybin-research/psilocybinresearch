"""Scope the exported service worker to its own caches and support Apache hosting."""
from pathlib import Path
import sys
root = Path(sys.argv[1])
worker = root / "shinylive-sw.js"
text = worker.read_text()
text = text.replace("return key.indexOf(version + cacheName) !== 0;", "return key.endsWith(cacheName) && key !== version + cacheName;")
worker.write_text(text)
(root / ".htaccess").write_text("DirectoryIndex index.html\n")
# Some shared hosts block .pem files, including this public CA trust bundle.
engine = root / "shinylive/webr/R.js"
cert = root / "shinylive/webr/vfs/etc/ssl/cert.pem"
if cert.exists():
    cert.with_suffix(".pem.txt").write_bytes(cert.read_bytes())
    engine.write_text(engine.read_text().replace("'vfs/etc/ssl/cert.pem'", "'vfs/etc/ssl/cert.pem.txt'"))
