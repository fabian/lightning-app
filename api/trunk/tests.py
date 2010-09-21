#!/usr/bin/env python

import unittest
import sys
import os

sys.path = sys.path + ['/usr/local/google_appengine', '/usr/local/google_appengine/lib/django', '/usr/local/google_appengine/lib/webob', '/usr/local/google_appengine/lib/yaml/lib', '/usr/local/google_appengine/google/appengine','/Users/aral/singularity/']

from google.appengine.api import apiproxy_stub_map
from google.appengine.api import datastore_file_stub
from google.appengine.ext import webapp
import mocker
import webtest
import resources
import models

class Tests(mocker.MockerTestCase):
    
    def stub_datastore(self):
        apiproxy_stub_map.apiproxy = apiproxy_stub_map.APIProxyStubMap()
        stub = datastore_file_stub.DatastoreFileStub('lightning-app', None, None)
        apiproxy_stub_map.apiproxy.RegisterStub('datastore', stub)
    
    def mock_urbanairship(self):
        airship = self.mocker.replace("urbanairship.Airship")
        airship(mocker.ANY, mocker.ANY)
        self.urbanairship = self.mocker.mock()
        self.mocker.result(self.urbanairship)


class DevicesTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/devices', resources.DevicesResource), 
        ], debug=True)
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
        test = webtest.TestApp(self.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345", 'device_token': "EC1A770EE68DDC468FC3DFC0DB77BEC534EB2F6F4368B103EDF410D89B5D5CC0"})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')


class DeviceTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/devices/(.*)', resources.DeviceResource), 
        ], debug=True)
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_device(self):
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_get_wrong_device(self):
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Device 1 doesn't match authenticated device 2")


class DeviceListsTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/devices/(.*)/lists', resources.DeviceListsResource), 
        ], debug=True)
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_lists(self):
        
        list_a = models.List(title="List A", owner=self.device_one)
        list_a.put()
        
        list_b = models.List(title="List B", owner=self.device_one)
        list_b.put()
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"lists": [{"url": "http://localhost:80/api/lists/3", "id": 3, "title": "List A"}, {"url": "http://localhost:80/api/lists/4", "id": 4, "title": "List B"}]}')
    
    def test_get_lists_only_own(self):
        
        list_c = models.List(title="List C", owner=self.device_two)
        list_c.put()
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"lists": []}')


class ItemTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/items/(.*)', resources.ItemResource), 
        ], debug=True)
        
        self.device_one = models.Device(identifier="foobar", device_token="ABC123", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", device_token="ABC123", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_item(self):
        
        list = models.List(title="A random list", owner=self.device_one)
        list.put()
        
        item = models.Item(value="Some Item", list=list)
        item.put()
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/items/4", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/4", "id": 4, "value": "Some Item"}')


class ListPushTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/lists/(.*)/push', resources.ListPushResource), 
        ], debug=True)
        self.mock_urbanairship()
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="Groceries", owner=self.device)
        self.list.put()
        
        self.receiver = models.Device(identifier="receiver", device_token="ABC123", name="Max", secret="123")
        self.receiver.put()
        
        self.group = models.Group(name="Friends", owner=self.device, lists=[self.list.key()], token="R4ND0M")
        self.group.put()
        
        self.shared_list = models.SharedList(group=self.group, list=self.list, guest=self.receiver)
        self.shared_list.put()
        
        self.item_one = models.Item(value="Wine", list=self.list)
        self.item_one.put()
        
        self.item_two = models.Item(value="Bread", list=self.list)
        self.item_two.put()
        
        self.item_three = models.Item(value="Marmalade", list=self.list)
        self.item_three.put()
        
        self.urbanairship.push({'aps': {'badge': 0, 'alert': "Added Bread and Wine. Changed Butter to Marmalade."}}, aliases=['ag1saWdodG5pbmctYXBwcgwLEgZEZXZpY2UYAww'])
    
    def test_push_list(self):
        
        log = models.Log(device=self.device, item=self.item_one, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_two, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_three, list=self.list, action='modified', old="Butter")
        log.put()
        
        self.mocker.replay()
        test = webtest.TestApp(self.application)
        response = test.post("/api/lists/2/push", {'exclude': '1'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"notification": "Added Bread and Wine. Changed Butter to Marmalade.", "devices": [3]}')


class NotificationTests(Tests):
    
    def setUp(self):
        self.stub_datastore()       
        self.application = webapp.WSGIApplication([
            (r'/api/items', resources.ItemsResource), 
            (r'/api/items/(.*)', resources.ItemResource), 
        ], debug=True)
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="A random list", owner=self.device)
        self.list.put()
        
        self.item_one = models.Item(value="Wine", list=self.list)
        self.item_one.put()
    
    def test_get_notification(self):
        
        test = webtest.TestApp(self.application)
        
        response = test.post("/api/items", {'value': "Bread", 'list': '2'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        response = test.post("/api/items", {'value': "Butter", 'list': '2'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        response = test.put("/api/items/3", {'value': "Water"}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(self.list.get_notification(), "Added Bread and Butter. Changed Wine to Water.")
    
    def test_add_delete_notification(self):
        
        test = webtest.TestApp(self.application)
        
        response = test.post("/api/items", {'value': "Nothing", 'list': '2'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        response = test.delete("/api/items/4", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(self.list.get_notification(), "")


class GroupsTests(Tests):
    
    def setUp(self):
        self.stub_datastore()       
        self.application = webapp.WSGIApplication([
            (r'/api/groups', resources.GroupsResource), 
        ], debug=True)
        
        self.device = models.Device(identifier="foobar", device_token="ABC123", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="A random list", owner=self.device)
        self.list.put()
    
    def test_create_group(self):
        
        random = self.mocker.replace("os.urandom")
        random(8)
        self.mocker.result("98257")
        
        hexlify = self.mocker.replace("binascii.hexlify")
        hexlify("98257")
        self.mocker.result("xyz")
        
        self.mocker.replay()
        test = webtest.TestApp(self.application)
        
        response = test.post("/api/groups", {'name': "Friends", 'owner': '1'}, headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/groups/3", "owner": 1, "token": "xyz", "id": 3, "name": "Friends"}')


if __name__ == "__main__":
    os.environ['APPLICATION_ID'] = 'lightning-app'
    unittest.main()
