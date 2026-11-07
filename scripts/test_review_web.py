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
        self.root = Path(self.temp.name) / 'repo'
        self.root.mkdir()
        (self.root/'web').mkdir()
        (self.root/'web/index.html').write_text('<!doctype html>Library')
        (self.root/'reviews').mkdir()
        (self.root/'reviews/demo.md').write_text('# Demo\n\n**Reviewed:** 2026-11-01\n**Stack:** Python\n')
        (self.root/'reviews/demo.html').write_text('<h1>Guide</h1>')
        (self.root/'README.md').write_text('| [demo.md](reviews/demo.md) | [Demo](https://github.com/demo/demo) | MIT | ✅ Deploy candidate | A useful demo |\n')
        (self.root/'.git').mkdir()
        (self.root/'.git/config').write_text('private')
        self.server = web.App(('127.0.0.1', 0), self.root, state_dir=Path(self.temp.name)/'private')
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.base = f'http://127.0.0.1:{self.server.server_port}'
        request = Request(self.base+'/api/login', data=b'{"username":"admin","password":"admin"}', headers={'Content-Type':'application/json','X-Public-Data':'1'})
        with urlopen(request) as response:
            self.cookie = response.headers['Set-Cookie'].split(';')[0]
    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(); self.server.access.db.close(); self.temp.cleanup()
    def call(self,path,method='GET',data=None,headers=None):
        hdr={'Content-Type':'application/json','X-Public-Data':'1','Cookie':self.cookie}
        hdr.update(headers or {})
        request=Request(self.base+path,method=method,headers=hdr,data=json.dumps(data).encode() if data is not None else None)
        try: response=urlopen(request)
        except HTTPError as exc: response=exc
        body=response.read()
        status=response.status
        content_type=response.headers.get('Content-Type','')
        response.close()
        return status, json.loads(body) if 'application/json' in content_type else body
    def test_local_auth_and_roles(self):
        cookie = self.cookie
        self.cookie = ''
        self.assertEqual(self.call('/api/catalog')[0], 200)
        self.assertEqual(self.call('/content/reviews/demo.md')[0], 200)
        self.assertEqual(self.call('/api/settings/ai')[0], 401)
        self.assertEqual(self.call('/api/settings/users')[0], 401)
        self.assertEqual(self.call('/api/requests')[0], 200)
        self.assertEqual(self.call('/content/reviews/demo.html')[0], 200)
        self.assertEqual(self.call('/api/agent')[0], 401)
        self.assertEqual(self.call('/api/requests','POST',{'title':'Anonymous','url':'https://example.com'})[0],401)
        self.assertEqual(self.call('/api/requests/'+'a'*32,'PATCH',{'revision':1,'status':'completed'})[0],401)
        self.assertEqual(self.call('/api/agent','POST',{'action':'ask','query':'demo'})[0],401)
        self.assertEqual(self.call('/api/settings/ai','POST',{})[0],401)
        self.assertEqual(self.call('/api/login','POST',{'username':'admin','password':'wrong'})[0],401)
        self.cookie = cookie
        self.assertEqual(self.call('/api/settings/users','POST',{'username':'reader','password':'pass','role':'user','active':True})[0],200)
        token,user = self.server.access.login('reader','pass','test')
        self.cookie = 'pd_session='+token
        self.assertEqual(self.call('/api/catalog')[0],200)
        self.assertEqual(self.call('/api/settings/ai')[0],403)
        self.assertEqual(self.call('/api/settings/users','POST',{})[0],403)
        self.assertEqual(self.call('/api/agent','POST',{'action':'refresh'})[0],403)
        self.assertEqual(self.call('/api/logout','POST',{})[0],200)
        self.assertEqual(self.call('/api/catalog')[0],200)
        self.cookie=cookie
        admin=self.call('/api/settings/users')[1]['users'][0]
        self.assertEqual(self.call('/api/settings/users','POST',dict(admin,active=False))[0],400)

    def test_ai_settings_are_write_only(self):
        secret={'name':'Router','endpoint':'https://private.example/v1','model':'private-model','api_key':'secret-key','enabled':True}
        self.assertEqual(self.call('/api/settings/ai','POST',secret)[0],200)
        configs=self.call('/api/settings/ai')[1]['configurations']
        self.assertEqual(set(configs[0]),{'id','name','enabled'})
        for route in ['/api/settings/ai','/api/agent','/api/catalog']:
            body=json.dumps(self.call(route)[1])
            for k in ('endpoint','model','api_key'): self.assertNotIn(secret[k],body)
        self.assertEqual(self.call('/api/settings/ai','POST',{'id':configs[0]['id'],'name':'Renamed','enabled':False})[0],200)
        self.assertFalse(self.call('/api/settings/ai')[1]['configurations'][0]['enabled'])
        from local_access import Access
        reopened=Access(Path(self.temp.name)/'private')
        self.assertEqual(reopened.configurations()[0]['name'],'Renamed')
        reopened.db.close()
        self.assertEqual(self.call('/api/settings/ai','POST',{'id':configs[0]['id'],'delete':True})[0],200)
        self.assertEqual(self.call('/api/settings/ai')[1]['configurations'],[])

    def test_proxy_request_and_error_redaction(self):
        import io
        from unittest.mock import patch, MagicMock
        secret={'name':'Router','endpoint':'https://private.example/v1','model':'private-model','api_key':'secret-key','enabled':True}
        self.call('/api/settings/ai','POST',secret)
        opener=MagicMock()
        opener.open.return_value=io.BytesIO(json.dumps({'choices':[{'message':{'content':'secret-key private-model https://private.example/v1 answer'}}]}).encode())
        with patch('local_access.build_opener',return_value=opener):
            status, result=self.call('/api/agent','POST',{'action':'ask','query':'demo'})
        self.assertEqual(status,200)
        self.assertEqual(result['answer'],'[redacted] [redacted] [redacted] answer')
        request=opener.open.call_args.args[0]
        self.assertEqual(request.full_url,secret['endpoint']+'/chat/completions')
        self.assertEqual(request.get_header('Authorization'),'Bearer secret-key')
        payload=json.loads(request.data)
        self.assertEqual(payload['model'],'private-model')
        self.assertNotIn('secret-key',json.dumps(payload))
        self.assertNotIn('private.example',json.dumps(payload))
        with patch('local_access.build_opener',side_effect=OSError('secret-key private.example')):
            status,result=self.call('/api/agent','POST',{'action':'ask','query':'demo'})
        self.assertEqual(status,400)
        self.assertNotIn('secret-key',json.dumps(result))
        self.assertNotIn('private.example',json.dumps(result))

    def test_user_changes_revoke_sessions_and_preserve_accounts(self):
        access=self.server.access
        access.save_user({'username':'reader','password':'old','role':'user','active':True})
        token,reader=access.login('reader','old','test')
        access.save_user(dict(reader,password='new',active=True))
        self.assertIsNone(access.user(token))
        self.assertIsNone(access.login('reader','old','test'))
        self.assertIsNotNone(access.login('reader','new','test'))
        admin=next(u for u in access.users() if u['username']=='admin')
        with self.assertRaises(ValueError): access.save_user(dict(admin,username='reader',active=True))
        self.assertEqual(len(access.users()),2)
        self.assertEqual(access.user(self.cookie.split('=',1)[1])['username'],'admin')
        for route in ('users','ai'):
            self.assertEqual(self.call('/api/settings/'+route,'POST',{'id':['bad']})[0],400)

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
        with urlopen(Request(self.base+'/c%6fntent/reviews/demo.html', headers={'Cookie':self.cookie})) as response:
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
