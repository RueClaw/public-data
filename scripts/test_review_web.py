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
        return response.status, json.loads(body) if 'application/json' in response.headers.get('Content-Type','') else body
    def test_catalog_and_guide(self):
        status,data=self.call('/api/catalog'); self.assertEqual(status,200)
        item=data['items'][0]; self.assertEqual(item['html'],'reviews/demo.html'); self.assertEqual(item['description'],'A useful demo'); self.assertEqual(item['date'],'2026-11-01')
        self.assertEqual(self.call('/content/reviews/demo.html'),(200,b'<h1>Guide</h1>'))
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

if __name__=='__main__': unittest.main()
