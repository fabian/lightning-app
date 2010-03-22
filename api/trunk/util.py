import re
from cgi import parse_qs
from urlparse import urlparse
from google.appengine.ext import webapp
from django.utils import simplejson
from models import Device

def json(handler_method):
    
    def convert(self, *args):
        result = handler_method(self, *args)
        if result:
            self.response.out.write(simplejson.dumps(result))
        
    return convert


def device_required(handler_method):
    
    def check_device(self, *args):
        
        if self.get_auth() == None:
            # authentication failed
            self.error(401)
            self.response.out.write("No device header found!")
        else:
            return handler_method(self, *args)
    
    return check_device


class Resource(webapp.RequestHandler):
    
    def get_auth(self):
        
        if hasattr(self, 'auth'):
            return self.auth
        else:
            self.auth = None
            try:
                # authenticate client with device header
                header = urlparse(self.request.headers["Device"])
                id = re.compile(r'^/api/devices/(.*)$').match(header.path).group(1)
                secret = parse_qs(header.query)['secret'][0]
                
                device = Device.get_by_id(int(id))
                if device:
                    if device.secret == secret:
                        self.auth = device
            
            except KeyError, IndexError:
                pass
            
            return self.auth
