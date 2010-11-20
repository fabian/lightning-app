import os
from google.appengine.dist import use_library

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
use_library('django', '1.1')

from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from resources.device import DevicesResource, DeviceResource
from resources.list import DeviceListsResource, DeviceListResource, ListsResource, ListResource
from resources.notification import ListPushResource, ListUnreadResource
from resources.item import ItemsResource, ItemResource

application = webapp.WSGIApplication([
    (r'/api/devices', DevicesResource),
    (r'/api/devices/(.*)/lists', DeviceListsResource),
    (r'/api/devices/(.*)/lists/(.*)', DeviceListResource),
    (r'/api/devices/(.*)', DeviceResource),
    (r'/api/lists', ListsResource),
    (r'/api/lists/(.*)/push', ListPushResource),
    (r'/api/lists/(.*)/unread', ListUnreadResource),
    (r'/api/lists/(.*)', ListResource),
    (r'/api/items', ItemsResource),
    (r'/api/items/(.*)', ItemResource),
], debug=True)

def main():
	
	run_wsgi_app(application)

if __name__ == "__main__":
	main()
