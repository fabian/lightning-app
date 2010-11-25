import os
import logging
import binascii
import urbanairship
import settings
from util import Resource, json, device_required
from models import Device

class DevicesResource(Resource):
    
    @json
    def post(self):
        
        # generate random secret
        secret = binascii.hexlify(os.urandom(64))
        
        device = Device(name=self.request.get('name'), identifier=self.request.get('identifier'), device_token=self.request.get('device_token'), secret=secret)
        
        device.put()
        
        logging.debug("New device with id %s created.", device.key().id())
        
        # register with Urban Airship
        airship = urbanairship.Airship(settings.URBANAIRSHIP_APPLICATION_KEY, settings.URBANAIRSHIP_MASTER_SECRET)
        airship.register(device.device_token, alias=str(device.key()))
        
        logging.debug("Registered device %s with device token %s at Urban Airship.", device.key().id(), device.device_token)
        
        protocol = self.request._environ['wsgi.url_scheme']
        host = self.request._environ['HTTP_HOST']
        id = device.key().id()
        url = "%s://%s/api/devices/%s?secret=%s" % (protocol, host, id, secret)
        
        return {'id': id, 'url': url, 'secret': secret}


class DeviceResource(Resource):
    
    @device_required
    @json
    def put(self, id):
    
        device = Device.get_by_id(int(id))
        
        # device must match authenticated device
        if device.key() == self.get_auth().key():
            
            # see http://code.google.com/p/googleappengine/issues/detail?id=719
            import cgi
            params = cgi.parse_qs(self.request.body)
            
            device.name = params['name'][0]
            device.put()
        
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key().id(), self.get_auth().key().id()))
    
    @device_required
    @json
    def get(self, id):
        
        device = Device.get_by_id(int(id))
        
        # device must match authenticated device
        if device.key() == self.get_auth().key():
            
            protocol = self.request._environ['wsgi.url_scheme']
            host = self.request._environ['HTTP_HOST']
            id = device.key().id()
            secret = device.secret
            url = u"%s://%s/api/devices/%s?secret=%s" % (protocol, host, id, secret)
            
            return {'id': id, 'url': url, 'secret': secret}
            
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key().id(), self.get_auth().key().id()))

