from datetime import datetime
import webtest

from tests.util import Tests
import models
import api

class ListReadTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="Groceries", owner=self.device, token="xzy")
        self.list.put()
        models.ListDevice(device=self.device, list=self.list, read=datetime(2010, 01, 01, 12, 00, 00), unread=72).put()
        
        self.device_second = models.Device(identifier="raboof", device_token="ABC123", name="Uninvolved Device", secret="xyz")
        self.device_second.put()
    
    def test_read_list(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/1/read", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"device": 1, "list": 2}')
        
        listdevice = models.ListDevice.get_by_id(3)
        self.assertNotEqual(listdevice.read, datetime(2010, 01, 01, 12, 00, 00))
        self.assertEqual(listdevice.unread, 0)
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/2/unread')
            self.assertEqual(task['headers'][0], ('Environment', ''))
    
    def test_read_wrong_id(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/99/devices/1/read", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list with id 99")
    
    def test_read_invalid_id(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/aaa/devices/1/read", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list with id aaa")
    
    def test_read_no_access(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/4/read", headers={'Device': 'http://localhost:80/api/devices/4?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Authenticated device 4 has no access to list")
    
    def test_read_wrong_device(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/99/read", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=400)
        
        self.assertEqual(response.body, "Device 99 not found")
    
    def test_read_invalid_device(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/aaa/read", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=400)
        
        self.assertEqual(response.body, "Device aaa not found")
    
    def test_environment(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/1/read", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/2/unread')
            self.assertEqual(task['headers'][0], ('Environment', 'test'))


class UnreadTests(Tests):

    def setUp(self):
        self.stub_datastore()
    
    def test_unread_wrong_id(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/99/unread", status=404)
        
        self.assertEqual(response.body, "Can't get list with id 99")
    
    def test_unread_invalid_id(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/aaa/unread", status=404)
        
        self.assertEqual(response.body, "Can't get list with id aaa")
