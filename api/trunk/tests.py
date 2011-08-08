#!/usr/bin/env python

import unittest
import sys
import os
from datetime import datetime

sys.path = sys.path + ['/usr/local/google_appengine', '/usr/local/google_appengine/lib/django', '/usr/local/google_appengine/lib/webob', '/usr/local/google_appengine/lib/yaml/lib', '/usr/local/google_appengine/google/appengine','/Users/aral/singularity/']

from google.appengine.api import apiproxy_stub_map
from google.appengine.api import datastore_file_stub
from google.appengine.api.taskqueue import taskqueue_stub
from google.appengine.api.urlfetch import DownloadError
import mocker
import webtest
import urbanairship
from resources.device import DevicesResource, DeviceResource
from resources.list import DeviceListsResource, DeviceListResource, ListsResource, ListResource
from resources.notification import ListReadResource, ListPushResource, ListUnreadResource
from resources.item import ItemsResource, ItemResource
import models
import api
import notifications
import util


class Tests(mocker.MockerTestCase):
    
    def stub_datastore(self):
        apiproxy_stub_map.apiproxy = apiproxy_stub_map.APIProxyStubMap()
        stub = datastore_file_stub.DatastoreFileStub('lightning-app', None, None)
        apiproxy_stub_map.apiproxy.RegisterStub('datastore', stub)
        self.taskqueue_stub = taskqueue_stub.TaskQueueServiceStub()
        apiproxy_stub_map.apiproxy.RegisterStub('taskqueue', self.taskqueue_stub)
    
    def mock_urbanairship(self, key='', secret=''):
        airship = self.mocker.replace("urbanairship.Airship")
        airship(key, secret)
        self.mocker.count(1, None)
        self.urbanairship = self.mocker.mock()
        self.mocker.result(self.urbanairship)


class PingTests(Tests):

    def setUp(self):
        self.stub_datastore()
    
    def test_ping(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/ping")
        
        self.assertEqual(response.body, '{"ping": "pong"}')


class DevicesTests(Tests):

    def setUp(self):
        self.stub_datastore()
        self.mock_secret()
    
    def mock_secret(self):
        
        random = self.mocker.replace("os.urandom")
        random(64)
        self.mocker.result("84763")
        
        hexlify = self.mocker.replace("binascii.hexlify")
        hexlify("84763")
        self.mocker.result("abc")
    
    def test_create_device(self):
        
        self.mock_urbanairship()
        self.urbanairship.register("EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345", 'device_token': "EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0"})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_create_device_without_token(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.post("/api/devices", {'name': "My random device", 'identifier': "000-000-000"})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_create_device_download_error(self):
        
        self.mock_urbanairship()
        self.urbanairship.register("EC1A77", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        self.mocker.throw(DownloadError)
        
        logging = self.mocker.replace('logging')
        logging.error(mocker.ARGS)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345", 'device_token': "EC1A77"})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_create_device_urbanairship_failure(self):
        
        self.mock_urbanairship()
        self.urbanairship.register("EC1A77", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        self.mocker.throw(urbanairship.AirshipFailure(500, 'Server Error'))
        
        logging = self.mocker.replace('logging')
        logging.error(mocker.ARGS)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345", 'device_token': "EC1A77"})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_environment(self):
        
        self.mock_urbanairship('Adr6zi712Z', 'Jei1co955G')
        self.urbanairship.register(mocker.ANY, alias=mocker.ANY)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345", 'device_token': "789012"}, headers={'Environment': 'test'})


class DeviceTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_device(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_get_wrong_device(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Device 1 doesn't match authenticated device 2")
    
    def test_get_wrong_secret(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/1?secret=qwert'}, status=403)
        
        self.assertEqual(response.body, "Secret qwert doesn't match device secret!")
    
    def test_get_missing_device(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/99?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Device 99 not found!")
    
    def test_get_invalid_id(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/aaa", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Device aaa not found")
    
    def test_get_no_header(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1", status=401)
        
        self.assertEqual(response.body, "No device header found!")
    
    def test_change_device(self):
        
        self.mock_urbanairship()
        self.urbanairship.register("EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.put("/api/devices/1", {'name': 'New Name', 'device_token': 'EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        device = models.Device.get_by_id(1)
        self.assertEqual(device.name, 'New Name')
        self.assertEqual(device.device_token, 'EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0')
    
    def test_change_device_without_device_token(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/devices/1", {'name': 'New Name'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        device = models.Device.get_by_id(1)
        self.assertEqual(device.name, 'New Name')
    
    def test_change_invalid_id(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/devices/aaa", {'name': 'New Name'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Device aaa not found")
    
    def test_wrong_change_device(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/devices/1", {'name': 'New Name'}, headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Device 1 doesn't match authenticated device 2")
    
    def test_change_device_download_error(self):
        
        self.mock_urbanairship()
        self.urbanairship.register("EC1A770", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        self.mocker.throw(DownloadError)
        
        logging = self.mocker.replace('logging')
        logging.error(mocker.ARGS)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.put("/api/devices/1", {'name': 'New Name', 'device_token': 'EC1A770'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        device = models.Device.get_by_id(1)
        self.assertEqual(device.name, 'New Name')
        self.assertEqual(device.device_token, 'EC1A770')
    
    def test_change_device_urbanairship_failure(self):
        
        self.mock_urbanairship()
        self.urbanairship.register("EC1A770", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        self.mocker.throw(urbanairship.AirshipFailure(500, 'Server Error'))
        
        logging = self.mocker.replace('logging')
        logging.error(mocker.ARGS)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.put("/api/devices/1", {'name': 'New Name', 'device_token': 'EC1A770'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        device = models.Device.get_by_id(1)
        self.assertEqual(device.name, 'New Name')
        self.assertEqual(device.device_token, 'EC1A770')


class DeviceListsTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_lists(self):
        
        list_a = models.List(title="List A", owner=self.device_one, token="xzy")
        list_a.put()
        models.ListDevice(device=self.device_one, list=list_a).put()
        
        list_b = models.List(title="List B", owner=self.device_one, token="xzy")
        list_b.put()
        models.ListDevice(device=self.device_one, list=list_b).put()
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"lists": [{"url": "http://localhost:80/api/lists/3", "token": "xzy", "unread": 0, "id": 3, "title": "List A"}, {"url": "http://localhost:80/api/lists/5", "token": "xzy", "unread": 0, "id": 5, "title": "List B"}]}')
    
    def test_get_lists_only_own(self):
        
        list_c = models.List(title="List C", owner=self.device_two, token="xzy")
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
        
        list = models.List(title="Some List", token="QWERT")
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
        
        response = self.test.post("/api/lists", {'title': "Groceries", 'owner': "1"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/3", "token": "foobar", "id": 3, "title": "Groceries"}')
    
    def test_create_wrong_owner(self):
        
        self.test = webtest.TestApp(api.application)
        
        response = self.test.post("/api/lists", {'title': "Groceries", 'owner': "aaa"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get device for owner aaa")
    
    def test_create_no_access(self):
        
        self.test = webtest.TestApp(api.application)
        
        response = self.test.post("/api/lists", {'title': "Groceries", 'owner': "1"}, headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Owner 1 doesn't match authenticated device 2")


class ListTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device.put()
        
        self.list = models.List(title="A random list", owner=self.device, token="xzy")
        self.list.put()
        models.ListDevice(device=self.device, list=self.list).put()
        
        self.item_one = models.Item(value="Wine", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_one.put()
        
        self.item_two = models.Item(value="Bread", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_two.put()
        
        self.device_second = models.Device(identifier="raboof", device_token="ABC123", name="Uninvolved Device", secret="xyz")
        self.device_second.put()
    
    def test_get_list(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/lists/2", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/2", "items": [{"url": "http://localhost:80/api/items/4", "done": false, "id": 4, "value": "Wine", "modified": "2010-06-29 12:00:00"}, {"url": "http://localhost:80/api/items/5", "done": false, "id": 5, "value": "Bread", "modified": "2010-06-29 12:00:00"}], "id": 2, "title": "A random list"}')
    
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
        response = test.put("/api/lists/2", {'title': "New Title"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/2", "id": "2", "title": "New Title"}')
        
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

class ItemsTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
        
        self.list = models.List(title="A random list", owner=self.device_one, token="xzy")
        self.list.put()
        models.ListDevice(device=self.device_one, list=self.list).put()
        
        self.test = webtest.TestApp(api.application)
    
    def test_create_item(self):
        
        response = self.test.post("/api/items", {'list': "3", 'value': "Milk"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/5", "list": 3, "id": 5, "value": "Milk"}')
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/3/unread')
            self.assertEqual(task['headers'][0], ('Environment', ''))
    
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
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/3/unread')
            self.assertEqual(task['headers'][0], ('Environment', 'test'))
    

class ItemTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
        
        self.device_three = models.Device(identifier="stranger", device_token="ABC123", name="Third Device", secret="qwert")
        self.device_three.put()
        
        self.list = models.List(title="A random list", owner=self.device_one, token="xzy")
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
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/4/unread')
            self.assertEqual(task['headers'][0], ('Environment', ''))
    
    def test_update_conflict_item(self):
        
        response = self.test.put("/api/items/7", {'value': "Old Value", 'modified': "2010-06-29 12:00:00"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=409)
        
        self.assertEqual(response.body, "Conflict, has later modification")
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 0)
    
    def test_update_wrong_id(self):
        
        response = self.test.put("/api/items/99", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'Item 99 not found')
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 0)
    
    def test_update_invalid_id(self):
        
        response = self.test.put("/api/items/aaa", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'Item aaa not found')
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 0)
    
    def test_update_no_access(self):
        
        response = self.test.put("/api/items/7", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=403)
        
        self.assertEqual(response.body, 'Authenticated device 3 has no access to list of item')
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 0)
    
    def test_update_environment(self):
        
        response = self.test.put("/api/items/7", {'value': "New Value", 'done': "1",  'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/4/unread')
            self.assertEqual(task['headers'][0], ('Environment', 'test'))
    
    def test_delete_item(self):
        
        response = self.test.delete("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '')
        
        item = models.Item.get_by_id(7)
        self.assertTrue(item.deleted)
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/4/unread')
            self.assertEqual(task['headers'][0], ('Environment', ''))
    
    def test_delete_wrong_id(self):
        
        response = self.test.delete("/api/items/aaa", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, 'Item aaa not found')
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 0)
    
    def test_delete_no_access(self):
        
        response = self.test.delete("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/3?secret=qwert'}, status=403)
        
        self.assertEqual(response.body, 'Authenticated device 3 has no access to list of item')
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 0)
    
    def test_delete_environment(self):
        
        response = self.test.delete("/api/items/7", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})
        
        tasks = self.taskqueue_stub.GetTasks('default')
        self.assertEquals(len(tasks), 1)
        for task in tasks:
            self.assertEqual(task['url'], '/api/lists/4/unread')
            self.assertEqual(task['headers'][0], ('Environment', 'test'))


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


class ListPushTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="Groceries", owner=self.device, token="xzy")
        self.list.put()
        models.ListDevice(device=self.device, list=self.list, read=datetime(2010, 01, 01, 12, 00, 00)).put()
        
        self.receiver = models.Device(identifier="receiver", device_token="ABC123", name="Max", secret="123")
        self.receiver.put()
        models.ListDevice(device=self.receiver, list=self.list, read=datetime(2010, 05, 01, 12, 00, 00)).put()
        
        self.item_one = models.Item(value="Wine", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_one.put()
        
        self.item_two = models.Item(value="Bread", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_two.put()
        
        self.item_three = models.Item(value="Butter", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_three.put()
        
        self.item_four = models.Item(value="Honey", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_four.put()
        
        self.item_five = models.Item(value="Cheese", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_five.put()
        
        self.item_six = models.Item(value="Margarine", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_six.put()
        
        self.device_second = models.Device(identifier="raboof", device_token="ABC123", name="Uninvolved Device", secret="xyz")
        self.device_second.put()
    
    def test_push_list(self):
        
        log = models.Log(device=self.device, item=self.item_one, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_two, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_three, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_three, list=self.list, action='modified', old="Marmalade")
        log.put()
        
        log = models.Log(device=self.device, item=self.item_four, list=self.list, action='deleted', old="Honey")
        log.put()
        
        log = models.Log(device=self.device, item=self.item_five, list=self.list, action='modified', old="Milk")
        log.put()
        
        log = models.Log(device=self.device, item=self.item_six, list=self.list, action='deleted', old="Margarine", happened=datetime(2010, 04, 01, 00, 00, 00))
        log.put()
        
        # mocker screenplay
        self.mock_urbanairship()
        self.urbanairship.push({'aps': {'lightning_list': 2, 'badge': 4, 'alert': "Added Butter, Wine and Bread. Changed Milk to Cheese. Deleted Honey."}}, device_tokens=["ABC123"])
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/unread")
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(self.device.listdevice_set[0].unread, 0)
        self.assertEqual(self.receiver.listdevice_set[0].unread, 4)
        self.assertEqual(response.body, '{"devices": [4]}')
    
    def test_push_no_device_token(self):
        
        self.receiver.device_token = ''
        self.receiver.put()
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"devices": []}')
    
    def test_empty_list(self):
        
        # mocker screenplay
        self.mock_urbanairship()
        self.urbanairship.push({'aps': {'badge': 0}}, device_tokens=["ABC123"])
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/unread")
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"devices": [4]}')
    
    def test_push_wrong_id(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/99/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list with id 99")
    
    def test_push_invalid_id(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/aaa/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Can't get list with id aaa")
    
    def test_push_no_access(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/12?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Authenticated device 12 has no access to list")
    
    def test_push_wrong_exclude(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/99/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=400)
        
        self.assertEqual(response.body, "Device to exclude 99 not found")
    
    def test_push_invalid_exclude(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/aaa/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=400)
        
        self.assertEqual(response.body, "Device to exclude aaa not found")
    
    def test_push_download_error(self):
        
        log = models.Log(device=self.device, item=self.item_one, list=self.list, action='added')
        log.put()
        
        # mocker screenplay
        self.mock_urbanairship()
        self.urbanairship.push({'aps': {'lightning_list': 2, 'badge': 1, 'alert': "Added Wine."}}, device_tokens=["ABC123"])
        self.mocker.throw(DownloadError)
        
        logging = self.mocker.replace('logging')
        logging.error(mocker.ARGS)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/unread")
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(self.device.listdevice_set[0].unread, 0)
        self.assertEqual(self.receiver.listdevice_set[0].unread, 1)
        self.assertEqual(response.body, '{"devices": []}')
    
    def test_push_urbanairship_failure(self):
        
        log = models.Log(device=self.device, item=self.item_one, list=self.list, action='added')
        log.put()
        
        # mocker screenplay
        self.mock_urbanairship()
        self.urbanairship.push({'aps': {'lightning_list': 2, 'badge': 1, 'alert': "Added Wine."}}, device_tokens=["ABC123"])
        self.mocker.throw(urbanairship.AirshipFailure(500, 'Server Error'))
        
        logging = self.mocker.replace('logging')
        logging.error(mocker.ARGS)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/unread")
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(self.device.listdevice_set[0].unread, 0)
        self.assertEqual(self.receiver.listdevice_set[0].unread, 1)
        self.assertEqual(response.body, '{"devices": []}')
    
    def test_environment(self):
        
        log = models.Log(device=self.device, item=self.item_six, list=self.list, action='deleted', old="Margarine", happened=datetime(2010, 04, 01, 00, 00, 00))
        log.put()
        
        # mocker screenplay
        self.mock_urbanairship('Adr6zi712Z', 'Jei1co955G')
        self.urbanairship.push(mocker.ANY, device_tokens=mocker.ANY)
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc', 'Environment': 'test'})


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
    

class ListToTextTest(unittest.TestCase):

    def test_empty(self):
        self.assertEqual('', notifications.list_to_text([]))

    def test_one(self):
        self.assertEqual('Foo', notifications.list_to_text(['Foo']))

    def test_two(self):
        self.assertEqual('Bar and Foo', notifications.list_to_text(['Bar', 'Foo']))

    def test_more(self):
        self.assertEqual('Foo, Bar and Test', notifications.list_to_text(['Foo', 'Bar', 'Test']))


if __name__ == "__main__":
    os.environ['APPLICATION_ID'] = 'lightning-app'
    unittest.main()
