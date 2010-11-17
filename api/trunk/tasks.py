import os
from google.appengine.dist import use_library

os.environ['DJANGO_SETTINGS_MODULE'] = 'settings'
use_library('django', '1.1')

from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
import resources

application = webapp.WSGIApplication([
    (r'/tasks/lists/(.*)/unread', resources.ListUnreadResource),
], debug=True)

def main():
	
	run_wsgi_app(application)

if __name__ == "__main__":
	main()
