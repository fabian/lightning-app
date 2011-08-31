import webtest

from tests.util import Tests
import api

class PingTests(Tests):

    def setUp(self):
        self.stub_datastore()
    
    def test_ping(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/ping")
        
        self.assertEqual(response.body, '{"ping": "pong"}')
