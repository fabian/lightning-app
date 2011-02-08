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
            self.response.headers['Content-Type'] = 'application/json'
            self.response.out.write(simplejson.dumps(result))
        
    return convert

class WrongSecretException(Exception):
    def __init__(self, secret):
        self.secret = secret

class DeviceNotFoundException(Exception):
    def __init__(self, device):
        self.device = device

def device_required(handler_method):
    
    def check_device(self, *args):
        try:
            if self.get_auth() == None:
                # authentication failed
                self.error(401)
                self.response.out.write("No device header found!")
            else:
                return handler_method(self, *args)
        except WrongSecretException, (e):
            self.error(403)
            self.response.out.write("Secret %s doesn't match device secret!" % e.secret)
        except DeviceNotFoundException, (e):
            self.error(403)
            self.response.out.write("Device %s not found!" % e.device)
    
    return check_device

def environment(handler_method):
    
    ENVIRONMENTS = ('test', 'development', 'production')
    
    def get_environment(self, *args):
        
        # default settings
        self.settings = __import__('settings')
        
        try:
            # read environment
            self.environment = self.request.headers["Environment"]
        
        except KeyError:
            self.environment = ''
        
        if self.environment in ENVIRONMENTS:
            self.settings = __import__('settings_' + self.environment)
        
        return handler_method(self, *args)
    
    return get_environment

class Resource(webapp.RequestHandler):
    
    DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
    
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
                    else:
                        raise WrongSecretException(secret)
                else:
                    raise DeviceNotFoundException(id)
            
            except KeyError, IndexError:
                pass
            
            return self.auth
