#!/usr/bin/env python3
"""Dependency-free public-data library and file-backed review queue."""
import argparse
import hmac
import time
from functools import lru_cache
from safe_guide import GUIDE_CSP, sanitize_guide
import datetime as dt
import ipaddress
import json
import mimetypes
import os
from pathlib import Path
import re
import threading
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SECTIONS = ('reviews', 'patterns', 'prompts', 'agents', 'tools', 'notes', 'ai-patterns', 'inbox')
STATUSES = ('queued', 'reviewing', 'completed', 'declined')
LOCK = threading.Lock()
MAX_FILE_BYTES = 8 * 1024 * 1024
MAX_QUEUE_BYTES = 64 * 1024 * 1024
MAX_QUEUE_RECORDS = 10000
MAX_CATALOG_ITEMS = 20000
STATIC_FILES = {'index.html', 'app.js', 'styles.css', 'favicon.svg'}

@lru_cache(maxsize=8)
def guide_bytes(path, modified, size):
    return sanitize_guide(Path(path).read_text(errors='replace'))


def now():
    return dt.datetime.now(dt.timezone.utc).isoformat(timespec='seconds')

def canonical_url(value):
    if not isinstance(value, str) or len(value) > 2048:
        raise ValueError('Use a public HTTP or HTTPS URL (up to 2,048 characters).')
    value = value.strip()
    u = urlsplit(value)
    if u.scheme not in ('http', 'https') or not u.hostname or u.username or u.password:
        raise ValueError('Use a public HTTP or HTTPS URL without credentials.')
    host = u.hostname.lower().rstrip('.')
    if host == 'localhost' or '.' not in host or host.endswith(('.local', '.internal', '.localhost')):
        raise ValueError('Use a public source, not a local network address.')
    try:
        if not ipaddress.ip_address(host).is_global:
            raise ValueError('Use a public source, not a local network address.')
    except ValueError as exc:
        if 'public source' in str(exc):
            raise
    try:
        port = u.port
    except ValueError:
        raise ValueError('Invalid URL port.')
    netloc = f'[{host}]' if ':' in host else host
    if port and port != (443 if u.scheme == 'https' else 80):
        netloc += f':{port}'
    path = u.path.rstrip('/')
    if host == 'github.com' and path.endswith('.git'):
        path = path[:-4]
    if host == 'github.com':
        path = path.lower()
    return f'{u.scheme}://{netloc}{path}' + (f'?{u.query}' if u.query else '')

def plain(value):
    value = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', value)
    return re.sub(r'[*`_]', '', value).strip()

def catalog(root):
    rows = {}
    for line in (root / 'README.md').read_text().splitlines():
        if not line.startswith('| ['):
            continue
        cells = re.split(r'(?<!\\)\|', line.strip('|'))
        match = re.search(r'\]\((reviews/[^)]+\.md)\)', cells[0])
        if not match or len(cells) < 5:
            continue
        source = re.search(r'\[([^\]]+)\]\((https?://[^)]+)\)', cells[1])
        rows[match[1]] = {'source': source[2] if source else '', 'sourceName': source[1] if source else '',
                              'license': plain(cells[2]), 'rating': plain(cells[3]), 'description': plain('|'.join(cells[4:]))}
    result = []
    for section in SECTIONS:
        directory = root / section
        if not directory.exists():
            continue
        for file in sorted(directory.rglob('*.md')):
            if len(result) >= MAX_CATALOG_ITEMS:
                break
            if file.is_symlink() or file.stat().st_size > MAX_FILE_BYTES or not file.resolve().is_relative_to(root.resolve()):
                continue
            path = file.relative_to(root).as_posix()
            text = file.read_text(errors='replace')
            title = re.search(r'^#\s+(.+)', text, re.M)
            date = re.search(r'(?:Reviewed|Date):(?:\*\*)?\s*(\d{4}-\d{2}-\d{2})', text)
            stack = re.search(r'\*\*Stack:\*\*\s*(.+)', text)
            item = {'id': path, 'title': plain(title[1]) if title else file.stem.replace('-', ' ').title(),
                    'section': section, 'date': date[1] if date else '', 'path': path,
                    'html': file.with_suffix('.html').relative_to(root).as_posix() if file.with_suffix('.html').is_file() else None,
                    'stack': plain(stack[1]) if stack else '', 'rating': '', 'license': '', 'source': '', 'sourceName': '', 'description': ''}
            def field(label, clean=True):
                match = re.search(r'(?:\*\*)?' + label + r':(?:\*\*)?\s*([^|\n]+)', text)
                return (plain(match[1]) if clean else match[1].strip()) if match else ''
            source_field = field(r'(?:Repo|Repository|Source|Article|Paper|URL)', clean=False)
            source_url = re.search(r'https?://[^\s)>*]+', source_field)
            item['source'] = source_url[0] if source_url else ''
            item['license'] = field('License')
            item['rating'] = field('Rating')
            item.update(rows.get(path, {}))
            if not item['description']:
                what = re.search(r'\*\*What it is:\*\*\s*(.+)', text)
                paragraphs = [p.strip() for p in text.split('\n\n') if p.strip() and not p.lstrip().startswith(('#','|','-','*','>','```','---'))]
                item['description'] = plain(what[1] if what else (paragraphs[0] if paragraphs else ''))[:500]
            result.append(item)
    return result

class App(ThreadingHTTPServer):
    daemon_threads = True
    def __init__(self, address, root=ROOT, public_origin=None, queue_dir=None, gateway_token=None, max_connections=32):
        self.root = root.resolve()
        self.queue_dir = (queue_dir or root / 'review-requests').resolve()
        self.public_origin = public_origin
        self.gateway_token = gateway_token
        self.slots = threading.BoundedSemaphore(max_connections)
        self.catalog_lock = threading.Lock()
        self.rate_lock = threading.Lock()
        self.rate_tokens = 100.0
        self.rate_at = time.monotonic()
        self.cached = None
        self.cached_at = 0
        super().__init__(address, Handler)

    def process_request(self, request, address):
        if not self.slots.acquire(blocking=False):
            try:
                request.settimeout(1)
                request.sendall(b'HTTP/1.0 503 Service Unavailable\r\nContent-Length: 0\r\nRetry-After: 2\r\n\r\n')
            except OSError:
                pass
            finally:
                self.shutdown_request(request)
            return
        try:
            super().process_request(request, address)
        except BaseException:
            self.slots.release()
            raise
    def process_request_thread(self, request, address):
        try:
            super().process_request_thread(request, address)
        finally:
            self.slots.release()
    def allow_request(self):
        with self.rate_lock:
            at = time.monotonic()
            self.rate_tokens = min(100., self.rate_tokens + (at - self.rate_at) * 50)
            self.rate_at = at
            if self.rate_tokens < 1: return False
            self.rate_tokens -= 1
            return True

class Handler(BaseHTTPRequestHandler):
    def setup(self):
        self.request.settimeout(10)
        super().setup()
    def authorized(self):
        token = self.server.gateway_token
        if token and not hmac.compare_digest(self.headers.get('X-Public-Data-Gateway', ''), token):
            self.respond(403, {'error': 'Authenticated gateway required.'})
            return False
        if not self.server.allow_request():
            self.respond(429, {'error': 'Request limit reached. Try again shortly.'})
            return False
        return True

    server_version = 'PublicData/1.0'
    def log_message(self, fmt, *args):
        # Do not log submitted content or URL query strings.
        pass
    def respond(self, status, data, content_type='application/json; charset=utf-8', guide=False):
        body = json.dumps(data, ensure_ascii=False).encode() if content_type.startswith('application/json') else data
        if len(body) > MAX_FILE_BYTES:
            status, body, content_type = 413, b'{"error":"Response exceeds the size limit."}', 'application/json'

        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(body)))
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Referrer-Policy', 'no-referrer')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), payment=(), usb=()')
        if content_type.startswith('text/html') and guide:
            self.send_header('Content-Security-Policy', GUIDE_CSP)
        elif content_type.startswith('text/html'):
            self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; frame-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'self'")
        self.end_headers()
        if self.command != 'HEAD':
            self.wfile.write(body)
    def requests(self):
        directory = self.server.queue_dir
        if not directory.exists():
            return []
        files = list(directory.glob('*.json'))
        if len(files) > MAX_QUEUE_RECORDS or sum(p.stat().st_size for p in files) > MAX_QUEUE_BYTES:
            raise ValueError('Queue exceeds its configured storage limit.')
        return sorted([json.loads(p.read_text()) for p in files], key=lambda r:r['created'], reverse=True)
    def valid_host(self):
        host = self.headers.get('Host', '')
        local = {f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}', f'[::1]:{self.server.server_port}'}
        if self.server.public_origin:
            local.add(urlsplit(self.server.public_origin).netloc)
        return host in local
    def do_HEAD(self):
        self.do_GET()
    def do_GET(self):
        if not self.authorized(): return
        if not self.valid_host():
            return self.respond(403, {'error': 'Host not allowed.'})
        path = unquote(urlsplit(self.path).path)
        if path == '/api/catalog':
            with self.server.catalog_lock:
                if self.server.cached is None or time.monotonic() - self.server.cached_at > 30:
                    self.server.cached = catalog(self.server.root)
                    self.server.cached_at = time.monotonic()
            return self.respond(200, {'items': self.server.cached})
        if path == '/api/requests':
            return self.respond(200, {'requests': self.requests()})
        if path == '/api/health':
            return self.respond(200, {'ok': True})
        if path.startswith('/content/'):
            relative = Path(path[len('/content/'):])
            target = (self.server.root / relative).resolve()
            if not relative.parts or '..' in relative.parts or relative.parts[0] not in SECTIONS or not target.is_relative_to(self.server.root / relative.parts[0]) or target.suffix not in ('.md', '.html'):
                return self.respond(404, {'error': 'Not found.'})
        else:
            relative = 'index.html' if path == '/' else path.lstrip('/')
            if relative not in STATIC_FILES:
                return self.respond(404, {'error': 'Not found.'})
            target = (self.server.root / 'web' / relative).resolve()
            if not target.is_relative_to(self.server.root / 'web'):
                return self.respond(404, {'error': 'Not found.'})
        if not target.is_file():
            return self.respond(404, {'error': 'Not found.'})
        if target.stat().st_size > MAX_FILE_BYTES:
            return self.respond(413, {'error': 'File exceeds the size limit.'})
        kind = mimetypes.guess_type(str(target))[0] or 'application/octet-stream'
        if target.suffix == '.md':
            kind = 'text/plain'
        body = guide_bytes(str(target), target.stat().st_mtime_ns, target.stat().st_size) if target.suffix == '.html' and path.startswith('/content/') else target.read_bytes()
        self.respond(200, body, kind + '; charset=utf-8', guide=target.suffix == '.html' and path.startswith('/content/'))
    def do_POST(self):
        self.mutate()
    def do_PATCH(self):
        self.mutate()
    def mutate(self):
        if not self.authorized(): return
        if not self.valid_host():
            return self.respond(403, {'error': 'Host not allowed.'})
        origin = self.headers.get('Origin')
        allowed = {f'http://127.0.0.1:{self.server.server_port}', f'http://localhost:{self.server.server_port}'}
        if self.server.public_origin:
            allowed.add(self.server.public_origin)
        if self.headers.get('X-Public-Data') != '1' or (origin and origin not in allowed):
            return self.respond(403, {'error': 'Same-origin requests required.'})
        if self.headers.get('Content-Type', '').split(';')[0] != 'application/json':
            return self.respond(415, {'error': 'JSON required.'})
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if size < 2 or size > 16000:
                raise ValueError('Request is too large or empty.')
            data = json.loads(self.rfile.read(size))
            if not isinstance(data, dict):
                raise ValueError('Expected an object.')
            with LOCK:
                path = urlsplit(self.path).path
                if self.command == 'POST' and path == '/api/requests':
                    url = canonical_url(data.get('url', ''))
                    title = str(data.get('title', '')).strip()
                    notes = str(data.get('notes', '')).strip()
                    priority = data.get('priority', 'normal')
                    if not title or len(title) > 160 or len(notes) > 4000 or priority not in ('normal', 'high', 'low'):
                        raise ValueError('Title required (160 characters max); notes 4,000 max; invalid priority.')
                    records = self.requests()
                    if any(r['url'] == url and r['status'] in ('queued', 'reviewing') for r in records):
                        return self.respond(409, {'error': 'That source is already in the active queue.'})
                    if len(records) >= MAX_QUEUE_RECORDS:
                        return self.respond(409, {'error': 'Queue capacity reached.'})
                    item = {'id': uuid.uuid4().hex, 'title': title, 'url': url, 'notes': notes, 'priority': priority,
                            'status': 'queued', 'created': now(), 'updated': now(), 'revision': 1}
                    self.save(item)
                    return self.respond(201, item)
                if self.command == 'PATCH' and re.fullmatch(r'/api/requests/[a-f0-9]{32}', path):
                    target = self.server.queue_dir / (path.rsplit('/', 1)[1] + '.json')
                    if not target.exists():
                        return self.respond(404, {'error': 'Request not found.'})
                    item = json.loads(target.read_text())
                    if data.get('revision') != item['revision']:
                        return self.respond(409, {'error': 'This request changed. Refresh and try again.'})
                    if data.get('status') not in STATUSES:
                        raise ValueError('Invalid status.')
                    item.update(status=data['status'], updated=now(), revision=item['revision']+1)
                    self.save(item)
                    return self.respond(200, item)
                return self.respond(404, {'error': 'Not found.'})
        except (ValueError, TypeError, UnicodeError) as exc:
            return self.respond(400, {'error': str(exc)})
        except OSError:
            return self.respond(500, {'error': 'Could not save request. Check server storage permissions.'})
    def save(self, item):
        directory = self.server.queue_dir
        directory.mkdir(parents=True, exist_ok=True)
        encoded = (json.dumps(item, ensure_ascii=False, indent=2) + '\n').encode()
        target = directory / (item['id'] + '.json')
        total = sum(p.stat().st_size for p in directory.glob('*.json') if p != target)
        if total + len(encoded) > MAX_QUEUE_BYTES:
            raise ValueError('Queue storage limit reached.')
        temp = directory / ('.' + uuid.uuid4().hex + '.tmp')
        try:
            with temp.open('x') as stream:
                stream.write(encoded.decode())
                stream.flush()
                os.fsync(stream.fileno())
            temp.replace(directory / (item['id'] + '.json'))
        finally:
            temp.unlink(missing_ok=True)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8765)
    parser.add_argument('--host', default='127.0.0.1')
    parser.add_argument('--public-origin', help='Exact HTTPS origin accepted behind a trusted proxy')
    parser.add_argument('--queue-dir', type=Path, help='Persistent queue location (defaults to review-requests/)')
    args = parser.parse_args()
    gateway_token = os.environ.get('PUBLIC_DATA_GATEWAY_TOKEN')
    if args.public_origin and not gateway_token:
        parser.error('Public deployment requires PUBLIC_DATA_GATEWAY_TOKEN from a private environment file.')
    server = App((args.host, args.port), public_origin=args.public_origin, queue_dir=args.queue_dir, gateway_token=gateway_token)
    print(f'Public Data → http://{args.host}:{args.port}', flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()
