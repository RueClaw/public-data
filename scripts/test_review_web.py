"""Integration checks; isolated temporary data, never the real review queue."""
import importlib.util
import json
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.request import Request, urlopen
from urllib.error import HTTPError

spec = importlib.util.spec_from_file_location('review_web', Path(__file__).with_name('review-web.py'))
web = importlib.util.module_from_spec(spec)
spec.loader.exec_module(web)

class WebTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root/'web').mkdir()
        (self.root/'web/index.html').write_text('<!doctype html>Library')
        (self.root/'reviews').mkdir()
        (self.root/'reviews/demo.md').write_text('# Demo\n\n**Reviewed:** 2026-11-01\n**Stack:** Python\n')
        (self.root/'reviews/demo.html').write_text('<h1>Guide</h1>')
        (self.root/'README.md').write_text('| [demo.md](reviews/demo.md) | [Demo](https://github.com/demo/demo) | MIT | ✅ Deploy candidate | A useful demo |\n')
        (self.root/'.git').mkdir()
        (self.root/'.git/config').write_text('private')
        self.server = web.App(('127.0.0.1', 0), self.root)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.server.server_port}'
    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(); self.temp.cleanup()
    def call(self,path,method='GET',data=None,headers=None):
        hdr={'Content-Type':'application/json','X-Public-Data':'1'}
        hdr.update(headers or {})
        request=Request(self.base+path,method=method,headers=hdr,data=json.dumps(data).encode() if data is not None else None)
        try: response=urlopen(request)
        except HTTPError as exc: response=exc
        body=response.read()
        status=response.status
        content_type=response.headers.get('Content-Type','')
        response.close()
        return status, json.loads(body) if 'application/json' in content_type else body
    def test_catalog_and_guide(self):
        status,data=self.call('/api/catalog'); self.assertEqual(status,200)
        item=data['items'][0]; self.assertEqual(item['html'],'reviews/demo.html'); self.assertEqual(item['description'],'A useful demo'); self.assertEqual(item['date'],'2026-11-01')
        self.assertEqual(self.call('/content/reviews/demo.html'),(200,b'<!doctype html><h1>Guide</h1>'))
    def test_queue_persists_and_transitions_with_revision(self):
        status,item=self.call('/api/requests','POST',{'title':'A tool','url':'https://github.com/Owner/Tool.git/','notes':'Look at isolation','priority':'high'})
        self.assertEqual(status,201); self.assertEqual(item['url'],'https://github.com/owner/tool')
        self.assertEqual(len(list((self.root/'review-requests').glob('*.json'))),1)
        self.assertEqual(self.call('/api/requests')[1]['requests'][0],item)
        self.assertEqual(self.call('/api/requests','POST',{'title':'Duplicate','url':'https://github.com/owner/tool'})[0],409)
        path='/api/requests/'+item['id']
        self.assertEqual(self.call(path,'PATCH',{'status':'reviewing','revision':1})[0],200)
        self.assertEqual(self.call(path,'PATCH',{'status':'completed','revision':1})[0],409)
        self.assertEqual(self.call(path,'PATCH',{'status':'completed','revision':2})[1]['status'],'completed')
    def test_request_validation(self):
        for url in ['javascript:alert(1)','http://localhost/a','http://127.0.0.1/a','http://192.168.1.1','https://user:secret@example.com','http://[::1]/']:
            self.assertEqual(self.call('/api/requests','POST',{'url':url,'title':'No'})[0],400,url)
        self.assertEqual(self.call('/api/requests','POST',{'url':'https://example.com','title':''})[0],400)
    def test_origin_host_and_private_paths(self):
        self.assertEqual(self.call('/api/requests','POST',{}, {'Origin':'https://evil.example'})[0],403)
        self.assertEqual(self.call('/api/catalog',headers={'Host':'evil.example'})[0],403)
        for path in ['/.git/config','/content/../.git/config','/content/reviews/../../.git/config','/../README.md','/content/%2e%2e/.git/config']:
            self.assertEqual(self.call(path)[0],404,path)
    def test_static_csp(self):
        with urlopen(self.base) as response:
            self.assertIn("script-src 'self'",response.headers['Content-Security-Policy'])

    def test_guides_remove_active_content_and_set_sandbox(self):
        from safe_guide import sanitize_guide
        source = '<html><head><style>body{color:red}</style></head><body><script>fetch("/api/requests")</script><form><input></form><iframe src="https://evil.example"></iframe><svg onload="alert(1)"></svg><h2 onclick="alert(1)">Findings</h2><a href="javascript:alert(1)">Unsafe</a><section hidden>Hidden findings</section></body></html>'
        (self.root/'reviews/demo.html').write_text(source)
        status,body = self.call('/content/reviews/demo.html')
        self.assertEqual(status,200)
        for unsafe in [b'<script',b'<form',b'<iframe',b'<svg',b'onclick=',b'javascript:']:
            self.assertNotIn(unsafe,body)
        self.assertIn(b'Hidden findings',body)
        self.assertNotIn(b'<section hidden',body)
        with urlopen(self.base+'/c%6fntent/reviews/demo.html') as response:
            csp=response.headers['Content-Security-Policy']
            self.assertIn("script-src 'none'",csp)
            self.assertIn('sandbox;',csp)
            self.assertIn("connect-src 'none'",csp)
    def test_gateway_token_is_required_when_configured(self):
        self.server.gateway_token='test-only-secret'
        self.assertEqual(self.call('/api/catalog')[0],403)
        self.assertEqual(self.call('/api/catalog',headers={'X-Public-Data-Gateway':'wrong'})[0],403)
        self.assertEqual(self.call('/api/catalog',headers={'X-Public-Data-Gateway':'test-only-secret'})[0],200)
    def test_static_allowlist_and_cross_collection_traversal(self):
        (self.root/'web/README.md').write_text('Private deployment documentation')
        for path in ['/README.md','/content/reviews/../web/README.md','/content/reviews/../README.md']:
            self.assertEqual(self.call(path)[0],404,path)
    def test_rate_and_connection_limits(self):
        self.server.rate_tokens=0
        self.server.rate_at=web.time.monotonic()+10
        self.assertEqual(self.call('/api/health')[0],429)
        self.server.rate_tokens=100
        self.server.rate_at=web.time.monotonic()
        for _ in range(32): self.server.slots.acquire()
        try: self.assertEqual(self.call('/api/health')[0],503)
        finally:
            for _ in range(32): self.server.slots.release()
    def test_queue_storage_limit(self):
        from unittest.mock import patch
        with patch.object(web,'MAX_QUEUE_BYTES',10):
            status,data=self.call('/api/requests','POST',{'title':'No space','url':'https://example.com'})
            self.assertEqual(status,400)
            self.assertIn('storage limit',data['error'])

if __name__=='__main__': unittest.main()
