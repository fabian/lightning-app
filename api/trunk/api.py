from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
import resources

application = webapp.WSGIApplication([
    (r'/api/devices', resources.DevicesResource),
    (r'/api/devices/(.*)', resources.DeviceResource),
    (r'/api/lists', resources.ListsResource),
    (r'/api/items', resources.ItemsResource),
    (r'/api/items/(.*)', resources.ItemResource),
], debug=True)

def main():
	
	run_wsgi_app(application)

if __name__ == "__main__":
	main()
