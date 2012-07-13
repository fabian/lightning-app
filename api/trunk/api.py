import os
import logging
from google.appengine.dist import use_library

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
use_library('django', '1.1')

from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from resources.ping import PingResource
from resources.device import DevicesResource, DeviceResource
from resources.list import DeviceListsResource, DeviceListResource, ListsResource, ListResource
from resources.notification import ListReadResource, ListPushResource
from resources.item import ItemsResource, ItemResource

application = webapp.WSGIApplication([
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

def real_main():
	
	run_wsgi_app(application)

def profile_main():
    # This is the main function for profiling
    # We've renamed our original main() above to real_main()
    import cProfile, pstats, StringIO
    import lib.profiler.appengine.datastore
    lib.profiler.appengine.datastore.activate()
    prof = cProfile.Profile()
    prof = prof.runctx("real_main()", globals(), locals())
    stream = StringIO.StringIO()
    stats = pstats.Stats(prof, stream=stream)
    stats.sort_stats("time")  # Or cumulative
    stats.print_stats(80)  # 80 = how many to print
    # The rest is optional.
    # stats.print_callees()
    # stats.print_callers()
    logging.info("Profile data:\n%s", stream.getvalue())
    lib.profiler.appengine.datastore.show_summary()

main = profile_main

if __name__ == "__main__":
	main()
