from datetime import datetime
import webtest

from tests.util import Tests
import models
import api

class ItemsTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
        
        self.list = models.List(title="A random list", owner=self.device_one, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
        self.list.put()
        models.ListDevice(device=self.device_one, list=self.list).put()
        
        self.test = webtest.TestApp(api.application)
    
    def test_create_item(self):
        
        response = self.test.post("/api/items", {'list': "3", 'value': "Milk"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/5", "list": 3, "id": 5, "value": "Milk"}')
        
        # make sure list modified has been changed
        list = models.List.get_by_id(3)
        self.assertGreater(list.modified, datetime(2010, 06, 29, 13, 00, 00))
    
    def test_wrong_list(self):
        
        response = self.test.post("/api/items", {'list': "99", 'value': "Milk"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list 99")
    
    def test_invalid_list(self):
        
        response = self.test.post("/api/items", {'list': "aaa", 'value': "Milk"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list aaa")
    
    def test_no_access(self):
        
        response = self.test.post("/api/items", {'list': "3", 'value': "Milk"}, headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Authenticated device 2 has no access to list of item")
    
    def test_environment(self):
        
        response = self.test.post("/api/items", {'list': "3", 'value': "Milk"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})
    

class ItemTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
        
        self.device_three = models.Device(identifier="stranger", device_token="ABC123", name="Third Device", secret="qwert")
        self.device_three.put()
        
        self.list = models.List(title="A random list", owner=self.device_one, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
        self.list.put()
        models.ListDevice(device=self.device_one, list=self.list).put()
        models.ListDevice(device=self.device_two, list=self.list).put()
        
        self.item = models.Item(value="Some Item", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item.put()
        
        self.test = webtest.TestApp(api.application)
    
    def test_get_item(self):
        
        response = self.test.get("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/7", "done": false, "id": 7, "value": "Some Item"}')
    
    def test_wrong_id(self):
        
        response = self.test.get("/api/items/99", headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=404)
        
        self.assertEqual(response.body, 'Item 99 not found')
    
    def test_invalid_id(self):
        
        response = self.test.get("/api/items/aaa", headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=404)
        
        self.assertEqual(response.body, 'Item aaa not found')
    
    def test_no_access(self):
        
        response = self.test.get("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=403)
        
        self.assertEqual(response.body, 'Authenticated device 3 has no access to list of item')
    
    def test_update_item(self):
        
        response = self.test.put("/api/items/7", {'value': "New Value", 'done': "1",  'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/7", "done": true, "id": "7", "value": "New Value", "modified": "2010-06-29 12:00:01"}')
        
        item = models.Item.get_by_id(7)
        self.assertEqual(item.value, "New Value")
        self.assertTrue(item.done)
        
        # make sure list modified has been changed
        list = models.List.get_by_id(4)
        self.assertGreater(list.modified, datetime(2010, 06, 29, 13, 00, 00))
    
    def test_update_conflict_item(self):
        
        response = self.test.put("/api/items/7", {'value': "Old Value", 'modified': "2010-06-29 12:00:00"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=409)
        
        self.assertEqual(response.body, "Conflict, has later modification")
    
    def test_update_wrong_id(self):
        
        response = self.test.put("/api/items/99", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'Item 99 not found')
    
    def test_update_invalid_id(self):
        
        response = self.test.put("/api/items/aaa", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'Item aaa not found')
    
    def test_update_no_access(self):
        
        response = self.test.put("/api/items/7", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=403)
        
        self.assertEqual(response.body, 'Authenticated device 3 has no access to list of item')
    
    def test_update_environment(self):
        
        response = self.test.put("/api/items/7", {'value': "New Value", 'done': "1",  'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})
    
    def test_delete_item(self):
        
        response = self.test.delete("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '')
        
        item = models.Item.get_by_id(7)
        self.assertTrue(item.deleted)
        
        # make sure list modified has been changed
        list = models.List.get_by_id(4)
        self.assertGreater(list.modified, datetime(2010, 06, 29, 13, 00, 00))
    
    def test_delete_wrong_id(self):
        
        response = self.test.delete("/api/items/aaa", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'Item aaa not found')
    
    def test_delete_no_access(self):
        
        response = self.test.delete("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=403)
        
        self.assertEqual(response.body, 'Authenticated device 3 has no access to list of item')
    
    def test_delete_environment(self):
        
        response = self.test.delete("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})
    