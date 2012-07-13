import os
import logging
import webapp2

from google.appengine.ext.webapp.util import run_wsgi_app
from resources.ping import PingResource
from resources.device import DevicesResource, DeviceResource
from resources.list import DeviceListsResource, DeviceListResource, ListsResource, ListResource
from resources.notification import ListReadResource, ListPushResource
from resources.item import ItemsResource, ItemResource

app = webapp2.WSGIApplication([
    (r'/api/ping', PingResource),
    (r'/api/devices', DevicesResource),
    (r'/api/devices/(.*)/lists', DeviceListsResource),
    (r'/api/devices/(.*)/lists/(.*)', DeviceListResource),
    (r'/api/devices/(.*)', DeviceResource),
    (r'/api/lists', ListsResource),
    (r'/api/lists/(.*)/devices/(.*)/read', ListReadResource),
    (r'/api/lists/(.*)/devices/(.*)/push', ListPushResource),
    (r'/api/lists/(.*)', ListResource),
    (r'/api/items', ItemsResource),
    (r'/api/items/(.*)', ItemResource),
], debug=True)
