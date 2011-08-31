import mocker
import webtest
import urbanairship
from google.appengine.api.urlfetch import DownloadError

from tests.util import Tests
import models
import api

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
