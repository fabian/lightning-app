from datetime import datetime
import webtest

from tests.util import Tests
import models
import api

class ListsTests(Tests):
    
    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_create_list(self):
        
        random = self.mocker.replace("os.urandom")
        random(8)
        self.mocker.result("548312")
        
        hexlify = self.mocker.replace("binascii.hexlify")
        hexlify("548312")
        self.mocker.result("foobar")
        
        self.mocker.replay()
        self.test = webtest.TestApp(api.application)
        
        response = self.test.post("/api/lists", {'title': "Groceries", 'owner': "1", 'shared': "0"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/3", "shared": false, "token": "foobar", "id": 3, "title": "Groceries"}')
    
    def test_create_wrong_owner(self):
        
        self.test = webtest.TestApp(api.application)
        
        response = self.test.post("/api/lists", {'title': "Groceries", 'owner': "aaa", 'shared': "0"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get device for owner aaa")
    
    def test_create_no_access(self):
        
        self.test = webtest.TestApp(api.application)
        
        response = self.test.post("/api/lists", {'title': "Groceries", 'owner': "1", 'shared': "0"}, headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Owner 1 doesn't match authenticated device 2")


class ListTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device.put()
        
        self.list = models.List(title="A random list", owner=self.device, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
        self.list.put()
        models.ListDevice(device=self.device, list=self.list, permission='owner').put()
        
        self.item_one = models.Item(value="Wine", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_one.put()
        
        self.item_two = models.Item(value="Bread", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_two.put()
        
        self.device_second = models.Device(identifier="raboof", device_token="ABC123", name="Uninvolved Device", secret="xyz")
        self.device_second.put()
    
    def test_get_list(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/lists/2", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/2", "shared": false, "items": [{"url": "http://localhost:80/api/items/4", "done": false, "id": 4, "value": "Wine", "modified": "2010-06-29 12:00:00"}, {"url": "http://localhost:80/api/items/5", "done": false, "id": 5, "value": "Bread", "modified": "2010-06-29 12:00:00"}], "id": 2, "title": "A random list"}')
    
    def test_get_wrong_id(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/lists/aaa", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list with id aaa")
    
    def test_get_no_access(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/lists/2", headers={'Device': 'http://localhost:80/api/devices/6?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Authenticated device 6 has no access to list")
    
    def test_update_list(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/lists/2", {'title': "New Title", 'shared': "1"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/2", "shared": true, "id": "2", "title": "New Title"}')
        
        list = models.List.get_by_id(2)
        self.assertEqual(list.title, "New Title")
    
    def test_update_list_without_shared(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/lists/2", {'title': "New Title"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/2", "shared": false, "id": "2", "title": "New Title"}')
        
        list = models.List.get_by_id(2)
        self.assertEqual(list.title, "New Title")
    
    def test_update_wrong_id(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/lists/aaa", {'title': "New Title"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'List aaa not found')
    
    def test_update_no_access(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/lists/2", {'title': "New Title"}, headers={'Device': 'http://localhost:80/api/devices/6?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, 'Authenticated device 6 has no access to list')


class DeviceListsTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_lists(self):
        
        list_a = models.List(title="List A", owner=self.device_one, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
        list_a.put()
        models.ListDevice(device=self.device_one, list=list_a).put()
        
        list_b = models.List(title="List B", owner=self.device_one, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
        list_b.put()
        models.ListDevice(device=self.device_one, list=list_b).put()
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"lists": [{"title": "List A", "url": "http://localhost:80/api/lists/3", "token": "xzy", "shared": false, "unread": false, "id": 3}, {"title": "List B", "url": "http://localhost:80/api/lists/5", "token": "xzy", "shared": false, "unread": false, "id": 5}]}')
    
    def test_get_lists_only_own(self):
        
        list_c = models.List(title="List C", owner=self.device_two, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
        list_c.put()
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"lists": []}')
    
    def test_get_lists_wrong_owner(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/aaa/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get device aaa")
    
    def test_get_lists_no_access(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/2/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'}, status=403)
        
        self.assertEqual(response.body, "Device 2 doesn't match authenticated device 1")


class DeviceListTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
        
        list = models.List(title="Some List", token="QWERT", modified=datetime(2010, 06, 29, 12, 00, 00))
        list.put()
        
        self.test = webtest.TestApp(api.application)
    
    def test_create_device_list(self):
        
        response = self.test.put("/api/devices/1/lists/3", {'token': "QWERT"}, headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1/lists/3", "device": 1, "list": 3}')
        
        self.assertEqual(self.device_one.listdevice_set.count(), 1)
        
        for x in self.device_one.listdevice_set:
            self.assertEqual(x.device.key().id(), 1)
            self.assertEqual(x.list.key().id(), 3)
    
    def test_create_wrong_device(self):
        
        response = self.test.put("/api/devices/aaa/lists/3", {'token': "QWERT"}, headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get device with id aaa")
    
    def test_create_no_access(self):
        
        response = self.test.put("/api/devices/1/lists/3", {'token': "QWERT"}, headers={'Device': 'http://some.domain:8080/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Device 1 doesn't match authenticated device 2")
    
    def test_create_wrong_list(self):
        
        response = self.test.put("/api/devices/1/lists/aaa", {'token': "QWERT"}, headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list with id aaa")
    
    def test_create_wrong_token(self):
        
        response = self.test.put("/api/devices/1/lists/3", {'token': "WRONG"}, headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'}, status=403)
        
        self.assertEqual(response.body, "Token WRONG doesn't match token for list 3")
