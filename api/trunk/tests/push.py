from datetime import datetime
import mocker
import webtest
import urbanairship
from google.appengine.api.urlfetch import DownloadError

from tests.util import Tests
import models
import api

class ListPushTests(Tests):

    def setUp(self):
        self.stub_datastore()
        
        self.device = models.Device(identifier="foobar", device_token="123ABC", name="Peter", secret="abc")
        self.device.put()
        
        self.list = models.List(title="Groceries", owner=self.device, token="xzy", modified=datetime(2010, 06, 29, 12, 00, 00))
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
        
        self.item_seven = models.Item(value="Cervelat", list=self.list, modified=datetime(2010, 06, 29, 12, 00, 00))
        self.item_seven.put()
        
        self.device_second = models.Device(identifier="raboof", device_token="XYZ123", name="Uninvolved Device", secret="xyz")
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
        
        # Honey added by receiver
        log = models.Log(device=self.receiver, item=self.item_four, list=self.list, action='added')
        log.put()
        
        log = models.Log(device=self.device, item=self.item_four, list=self.list, action='deleted', old="Honey")
        log.put()
        
        log = models.Log(device=self.device, item=self.item_five, list=self.list, action='modified', old="Milk")
        log.put()
        
        log = models.Log(device=self.device, item=self.item_seven, list=self.list, action='completed')
        log.put()
        
        # old log
        log = models.Log(device=self.device, item=self.item_six, list=self.list, action='deleted', old="Margarine", happened=datetime(2010, 04, 01, 00, 00, 00))
        log.put()
        
        self.mock_urbanairship()
        
        # first push
        self.urbanairship.push({'aps': {'lightning_list': 2, 'badge': 1, 'alert': "Added Wine, Bread and Butter. Completed Cervelat. Changed Milk to Cheese. Deleted Honey."}}, device_tokens=["ABC123"])
        
        # second push
        self.urbanairship.push({'aps': {'lightning_list': 2, 'badge': 0, 'alert': "Deleted Cheese."}}, device_tokens=["ABC123"])
        
        # mocker screenplay
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
        self.assertEqual(response.body, '{"devices": [4]}')
        
        log = models.Log(device=self.device, item=self.item_five, list=self.list, action='deleted', old="Cheese")
        log.put()
        
        # read list
        response = test.post("/api/lists/2/devices/4/read", headers={'Device': 'http://localhost:80/api/devices/4?secret=123'})
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
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
        self.urbanairship.push({'aps': {'badge': 1}}, device_tokens=["ABC123"])
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
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
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/13?secret=xyz'}, status=403)
        
        self.assertEqual(response.body, "Authenticated device 13 has no access to list")
    
    def test_push_wrong_device(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/99/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Device to push 99 not found")
    
    def test_push_invalid_device(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/aaa/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=404)
        
        self.assertEqual(response.body, "Device to push aaa not found")
    
    def test_push_wrong_auth(self):
        
        self.mocker.replay()
        test = webtest.TestApp(api.application)
        
        response = test.post("/api/lists/2/devices/13/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'}, status=403)
        
        self.assertEqual(response.body, "Device 13 doesn't match authenticated device 1")
    
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
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
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
        
        response = test.post("/api/lists/2/devices/1/push", headers={'Device': 'http://localhost:80/api/devices/1?secret=abc'})
        
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
