#!/usr/bin/env python

import unittest
import sys
import os
from datetime import datetime

sys.path = sys.path + ['/usr/local/google_appengine', '/usr/local/google_appengine/lib/django', '/usr/local/google_appengine/lib/webob', '/usr/local/google_appengine/lib/yaml/lib', '/usr/local/google_appengine/google/appengine','/Users/aral/singularity/']

from google.appengine.api import apiproxy_stub_map
from google.appengine.api import datastore_file_stub
from google.appengine.api.labs.taskqueue import taskqueue_stub
import mocker
import webtest
from resources.device import DevicesResource, DeviceResource
from resources.list import DeviceListsResource, DeviceListResource, ListsResource, ListResource
from resources.notification import ListPushResource, ListUnreadResource
from resources.item import ItemsResource, ItemResource
import models
import api

class Tests(mocker.MockerTestCase):
    
    def stub_datastore(self):
        apiproxy_stub_map.apiproxy = apiproxy_stub_map.APIProxyStubMap()
        stub = datastore_file_stub.DatastoreFileStub('lightning-app', None, None)
        apiproxy_stub_map.apiproxy.RegisterStub('datastore', stub)
        stub = apiproxy_stub_map.apiproxy.GetStub('taskqueue')
        apiproxy_stub_map.apiproxy.RegisterStub('taskqueue', taskqueue_stub.TaskQueueServiceStub())
    
    def mock_urbanairship(self):
        airship = self.mocker.replace("urbanairship.Airship")
        airship(mocker.ANY, mocker.ANY)
        self.mocker.count(1, None)
        self.urbanairship = self.mocker.mock()
        self.mocker.result(self.urbanairship)


class DevicesTests(Tests):

    def setUp(self):
        self.stub_datastore()
        self.mock_urbanairship()
    
    def test_create_device(self):
        
        random = self.mocker.replace("os.urandom")
        random(64)
        self.mocker.result("84763")
        
        hexlify = self.mocker.replace("binascii.hexlify")
        hexlify("84763")
        self.mocker.result("abc")
        
        self.urbanairship.register("EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0", alias="ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAQw")
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345", 'device_token': "EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0"})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')


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
        
        self.assertEqual(response.body, '{"lists": [{"url": "http://localhost:80/api/lists/3", "unread": 0, "id": 3, "title": "List A"}, {"url": "http://localhost:80/api/lists/5", "unread": 0, "id": 5, "title": "List B"}]}')
    
    def test_get_lists_only_own(self):
        
        list_c = models.List(title="List C", owner=self.device_two, token="xzy")
        list_c.put()
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"lists": []}')


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
    
    def test_get_list(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/lists/2", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/lists/2", "items": [{"url": "http://localhost:80/api/items/4", "id": 4, "value": "Wine"}, {"url": "http://localhost:80/api/items/5", "id": 5, "value": "Bread"}], "id": 2, "title": "A random list"}')


class ItemTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
        
        self.list = models.List(title="A random list", owner=self.device_one, token="xzy")
        self.list.put()
        models.ListDevice(device=self.device_one, list=self.list).put()
        models.ListDevice(device=self.device_two, list=self.list).put()
        
        self.item = models.Item(value="Some Item", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item.put()
    
    def test_get_item(self):
        
        test = webtest.TestApp(api.application)
        response = test.get("/api/items/6", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/6", "id": 6, "value": "Some Item"}')
    
    def test_update_item(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/items/6", {'value': "New Value", 'modified': "2010-06-29 12:00:01"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/6", "id": "6", "value": "New Value", "modified": "2010-06-29 12:00:01"}')
    
    def test_update_conflict_item(self):
        
        test = webtest.TestApp(api.application)
        response = test.put("/api/items/6", {'value': "Old Value", 'modified': "2010-06-29 12:00:00"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=409)
        
        self.assertEqual(response.body, "Conflict, has later modification")


class ListPushTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="Groceries", owner=self.device, token="xzy")
        self.list.put()
        models.ListDevice(device=self.device, list=self.list).put()
        
        self.receiver = models.Device(identifier="receiver", device_token="ABC123", name="Max", secret="123")
        self.receiver.put()
        models.ListDevice(device=self.receiver, list=self.list).put()
        
        self.item_one = models.Item(value="Wine", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_one.put()
        
        self.item_two = models.Item(value="Bread", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_two.put()
        
        self.item_three = models.Item(value="Marmalade", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_three.put()
        
        # mocker screenplay
        self.mock_urbanairship()
        self.urbanairship.push({'aps': {'lightning_list': 2, 'badge': 3, 'alert': "Added Bread and Wine. Changed Butter to Marmalade."}}, device_tokens=["ABC123"])
    
    def test_push_list(self):
        
        log = models.Log(device=self.device, item=self.item_one, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_two, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_three, list=self.list, action='modified', old="Butter")
        log.put()
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/unread")
        
        response = test.post("/api/lists/2/push", {'exclude': '1'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"devices": [4]}')


if __name__ == "__main__":
    os.environ['APPLICATION_ID'] = 'lightning-app'
    unittest.main()
