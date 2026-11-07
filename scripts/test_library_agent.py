"""Shared operations and adapter integration; no network or real agents."""
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from library_agent import AgentService
import test_review_web as web_tests
web = web_tests.web

class AgentTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        (self.root/'reviews').mkdir()
        (self.root/'reviews/demo.md').write_text('# Demo\n**Reviewed:** 2020-01-01\n**Revision:** `'+'a'*40+'`\nHidden capability: transactional repair\n')
        (self.root/'README.md').write_text('| [demo](reviews/demo.md) | [demo](https://github.com/example/demo) | MIT | Study | Demo |\n')
        self.service = AgentService(self.root, web.catalog)
    def tearDown(self):
        self.temp.cleanup()
    def test_full_text_evidence_and_staleness(self):
        hit=self.service.run({'query':'transactional repair'})['results'][0]
        self.assertEqual(hit['line'],4)
        self.assertIn('transactional',hit['excerpt'])
        self.assertEqual(self.service.run({'action':'stale','days':90})['results'][0]['activity'],'Not checked')
        (self.root/'reviews/demo.md').write_text('# Demo\nNo date')
        self.assertIsNone(self.service.run({'action':'stale'})['results'][0]['ageDays'])
    def test_configuration_and_admission(self):
        for config in [[], {'commands':{'ask':'sh'}}, {'timeout':0}, {'github':'yes'}]:
            with self.assertRaises(ValueError): AgentService(self.root,web.catalog,config)
        for data in [{'action':'unknown'},{'action':'refresh','target':'../private'},{'action':'stale','github':True},{'action':'stale','days':-1},{'query':[]}]:
            with self.assertRaises(ValueError): self.service.run(data)
    def test_adapter_protocol_target_and_failure(self):
        code='import sys,json; p=json.load(sys.stdin); print(p["action"],p["target"]["id"],p["query"])'
        service=AgentService(self.root,web.catalog,{'commands':{'guide':[sys.executable,'-c',code]}})
        result=service.run({'action':'guide','target':'reviews/demo.md','query':'Improve anatomy'})
        self.assertIn('guide reviews/demo.md Improve anatomy',result['answer'])
        with self.assertRaises(ValueError): service.run({'action':'guide','target':'reviews/absent.md'})
        service.config['commands']['guide']=[sys.executable,'-c','raise SystemExit(2)']
        with self.assertRaisesRegex(ValueError,'failed'): service.run({'action':'guide','target':'reviews/demo.md'})
    def test_timeout_and_serialization(self):
        service=AgentService(self.root,web.catalog,{'commands':{'ask':[sys.executable,'-c','import time; time.sleep(10)']},'timeout':1})
        with self.assertRaisesRegex(ValueError,'time or output'): service.run({'action':'ask','query':'hello'})
        service.lock.acquire()
        try:
            with self.assertRaisesRegex(ValueError,'already running'): service.run({'action':'ask','query':'hello'})
        finally: service.lock.release()
    def test_github_compare_and_unknown(self):
        self.service.config['github']=True
        response=io.BytesIO(json.dumps({'ahead_by':42,'status':'ahead','html_url':'https://github.com/example/demo/compare/a...HEAD'}).encode())
        with patch('library_agent.urlopen',return_value=response) as fetch:
            result=self.service.run({'action':'stale','github':True,'days':36500})['results'][0]
            self.assertEqual(result['commitsAhead'],42)
            self.assertIn('a'*40+'...HEAD',fetch.call_args.args[0].full_url)
        with patch('library_agent.urlopen',side_effect=OSError):
            result=self.service.run({'action':'stale','github':True})['results'][0]
            self.assertIn('Unknown',result['activity'])
    def test_network_limit_counts_checked_not_only_stale(self):
        base=web.catalog(self.root)[0]
        service=AgentService(self.root,lambda root:[dict(base,id=str(n),date='2099-01-01') for n in range(30)],{'github':True})
        def response(*a,**kw): return io.BytesIO(b'{"ahead_by":0,"status":"identical"}')
        with patch('library_agent.urlopen',side_effect=response) as fetch:
            self.assertEqual(len(service.run({'action':'stale','github':True})['results']),20)
            self.assertEqual(fetch.call_count,20)

class AgentWebTest(web_tests.WebTest):
    def test_agent_api(self):
        self.assertEqual(self.call('/api/agent')[1]['actions'],['search','stale'])
        status,result=self.call('/api/agent','POST',{'action':'search','query':'Python'})
        self.assertEqual(status,200); self.assertEqual(result['results'][0]['id'],'reviews/demo.md')
        self.assertEqual(self.call('/api/agent','POST',{'action':'ask','query':'hi'})[0],400)
        self.assertEqual(self.call('/api/agent','POST',{'action':'search','query':'x'},{'Origin':'https://evil.example'})[0],403)
        self.server.agent.config={'commands':{'ask':[sys.executable,'-c','import json,sys; print(json.load(sys.stdin)["query"])']}}
        status,result=self.call('/api/agent','POST',{'action':'ask','query':'<script>untrusted</script>'})
        self.assertEqual(status,200); self.assertIn('<script>',result['answer'])

if __name__ == '__main__': unittest.main()
