from datetime import datetime
import mocker

from google.appengine.api import apiproxy_stub_map
from google.appengine.api import datastore_file_stub
from google.appengine.api.taskqueue import taskqueue_stub

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

    def mock_datetime(self, time=datetime(2010, 06, 29, 13, 00, 00)):
        datetime = self.mocker.replace('datetime.datetime')
        datetime.now()
        self.mocker.result(time)
