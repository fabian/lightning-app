#!/usr/bin/env python

import unittest
import sys
import os
import os.path
import mocker

# Change the following line to reflect wherever your
# app engine installation and the mocker library are
APPENGINE_PATH = '/usr/local/google_appengine'

# Add app-engine related libraries to your path
paths = [
    APPENGINE_PATH,
    os.path.join(APPENGINE_PATH, 'lib', 'django'),
    os.path.join(APPENGINE_PATH, 'lib', 'webob'),
    os.path.join(APPENGINE_PATH, 'lib', 'yaml', 'lib'),
]
for path in paths:
  if not os.path.exists(path): 
    raise 'Path does not exist: %s' % path
sys.path = paths + sys.path

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
from google.appengine.dist import use_library
use_library('django', '1.1')

from google.appengine.ext.webapp import Response

import resources
import models

class DevicesTests(mocker.MockerTestCase):

    def setUp(self):
        self.resource = resources.DevicesResource()
        self.resource.request = self.mocker.mock()
        self.resource.response = self.mocker.mock()
        self.resource.error = self.mocker.mock()
    
    def test_create_device(self):
        
        random = self.mocker.replace("os.urandom")
        random(64)
        self.mocker.result("84763")
        
        hexlify = self.mocker.replace("binascii.hexlify")
        hexlify("84763")
        self.mocker.result("abc")
        
        self.resource.request.get('name')
        self.mocker.result("My iPhone")
        self.resource.request.get('identifier')
        self.mocker.result("123345")
        
        device = self.mocker.mock()
        model = self.mocker.replace("models.Device")
        model(name="My iPhone", identifier="123345", secret="abc")
        self.mocker.result(device)
        device.put()
        
        self.resource.request._environ['HTTP_HOST']
        self.mocker.result("some.domain")
        
        device.key().id()
        self.mocker.result(2)
        
        self.resource.response.out.write('{"url": "http://some.domain/api/devices/2?secret=abc", "secret": "abc", "id": 2}')
        
        # REPLAY!
        self.mocker.replay()
        self.resource.post()

class DeviceTests(mocker.MockerTestCase):

    def setUp(self):
        self.resource = resources.DeviceResource()
        self.resource.request = self.mocker.mock()
        self.resource.response = self.mocker.mock()
        self.resource.error = self.mocker.mock()
        self.resource.get_auth = self.mocker.mock()
    
    def test_get_device(self):
        
        auth = self.mocker.mock()
        self.resource.get_auth()
        self.mocker.result(auth)
        self.mocker.count(2)
        
        device = self.mocker.mock()
        model = self.mocker.replace("models.Device")
        model.get_by_id(3)
        self.mocker.result(device)
        
        auth.key()
        self.mocker.result("abc")
        device.key()
        self.mocker.result("abc")
        
        self.resource.request._environ['HTTP_HOST']
        self.mocker.result("some.domain")
        
        device.key().id()
        self.mocker.result(3)
        
        device.secret
        self.mocker.result("abc")
        
        self.resource.response.out.write('{"url": "http://some.domain/api/devices/3?secret=abc", "secret": "abc", "id": 3}')
        
        # REPLAY!
        self.mocker.replay()
        self.resource.get("3")
    
    def test_get_wrong_device(self):
        
        auth = self.mocker.mock()
        self.resource.get_auth()
        self.mocker.result(auth)
        self.mocker.count(3)
        
        device = self.mocker.mock()
        model = self.mocker.replace("models.Device")
        model.get_by_id(3)
        self.mocker.result(device)
        
        auth.key()
        self.mocker.result("notabc")
        self.mocker.count(2)
        device.key()
        self.mocker.result("abc")
        self.mocker.count(2)
        
        self.resource.error(403)
        self.resource.response.out.write("Device abc doesn't match authenticated device notabc")
        
        # REPLAY!
        self.mocker.replay()
        self.resource.get("3")

class ItemTests(mocker.MockerTestCase):

    def setUp(self):
        self.resource = resources.ItemResource()
        self.resource.initialize(self.mocker.mock(), Response())
        self.resource.error = self.mocker.mock()
        self.resource.get_auth = self.mocker.mock()
        foo = self.mocker.replace("util.device_required")
    
    def test_get_item(self):
        
        auth = self.mocker.mock()
        self.resource.get_auth()
        self.mocker.result(auth)
        self.mocker.count(2)
        
        item = self.mocker.mock()
        model = self.mocker.replace("models.Item")
        model.get_by_id(7)
        self.mocker.result(item)
        
        auth.key()
        self.mocker.result("abc")
        item.list.owner.key()
        self.mocker.result("abc")
        
        self.resource.request._environ['HTTP_HOST']
        self.mocker.result("some.domain")
        
        key = item.key()
        self.mocker.count(2)
        key.id()
        self.mocker.result(7)
        self.mocker.count(2)
        
        item.value
        self.mocker.result("2l Milch")
        
        # REPLAY!
        self.mocker.replay()
        self.resource.get("7")
        
        self.assertEqual(self.resource.response.out.getvalue(), '{"url": "http://some.domain/api/items/7", "id": 7, "value": "2l Milch"}')


if __name__ == "__main__":
    unittest.main()

