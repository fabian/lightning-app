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


class DevicesTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/devices', resources.DevicesResource), 
        ], debug=True)
    
    def test_create_device(self):
        
        random = self.mocker.replace("os.urandom")
        random(64)
        self.mocker.result("84763")
        
        hexlify = self.mocker.replace("binascii.hexlify")
        hexlify("84763")
        self.mocker.result("abc")
        
        self.mocker.replay()
        test = webtest.TestApp(self.application)
        response = test.post("/api/devices", {'name': "My iPhone", 'identifier': "123345"})
        
        self.assertEqual('200 OK', response.status)
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')


class DeviceTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/devices/(.*)', resources.DeviceResource), 
        ], debug=True)
        
        self.device_one = models.Device(identifier="foobar", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_device(self):
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual('200 OK', response.status)
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/devices/1?secret=abc", "secret": "abc", "id": 1}')
    
    def test_get_wrong_device(self):
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1", headers={'Device': 'http://localhost:80/api/devices/2?secret=xyz'}, status=403)
        
        self.assertEqual('403 Forbidden', response.status)
        self.assertEqual(response.body, "Device 1 doesn't match authenticated device 2")


class DeviceListsTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/devices/(.*)/lists', resources.DeviceListsResource), 
        ], debug=True)
        
        self.device_one = models.Device(identifier="foobar", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_lists(self):
        
        list_a = models.List(title="List A", owner=self.device_one)
        list_a.put()
        
        list_b = models.List(title="List B", owner=self.device_one)
        list_b.put()
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual('200 OK', response.status)
        self.assertEqual(response.body, '{"lists": [{"url": "http://localhost:80/api/lists/3", "id": 3, "title": "List A"}, {"url": "http://localhost:80/api/lists/4", "id": 4, "title": "List B"}]}')
    
    def test_get_lists_only_own(self):
        
        list_c = models.List(title="List C", owner=self.device_two)
        list_c.put()
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/devices/1/lists", headers={'Device': 'http://some.domain:8080/api/devices/1?secret=abc'})
        
        self.assertEqual('200 OK', response.status)
        self.assertEqual(response.body, '{"lists": []}')


class ItemTests(Tests):

    def setUp(self):
        self.stub_datastore()        
        self.application = webapp.WSGIApplication([
            (r'/api/items/(.*)', resources.ItemResource), 
        ], debug=True)
        
        self.device_one = models.Device(identifier="foobar", name="Some Device", secret="abc")
        self.device_one.put()
        
        self.device_two = models.Device(identifier="raboof", name="Another Device", secret="xyz")
        self.device_two.put()
    
    def test_get_item(self):
        
        list = models.List(title="A random list", owner=self.device_one)
        list.put()
        
        item = models.Item(value="Some Item", list=list)
        item.put()
        
        test = webtest.TestApp(self.application)
        response = test.get("/api/items/4", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual('200 OK', response.status)
        self.assertEqual(response.body, '{"url": "http://localhost:80/api/items/4", "id": 4, "value": "Some Item"}')


if __name__ == "__main__":
    os.environ['APPLICATION_ID'] = 'lightning-app'
    unittest.main()
