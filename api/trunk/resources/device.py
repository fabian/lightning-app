import os
import logging
import binascii
import urbanairship
from util import Resource, json, device_required, environment
from models import Device

class DevicesResource(Resource):
    
    @environment
    @json
    def post(self):
        
        # generate random secret
        secret = binascii.hexlify(os.urandom(64))
        
        device = Device(name=self.request.get('name'), identifier=self.request.get('identifier'), device_token=self.request.get('device_token'), secret=secret)
        
        device.put()
        
        logging.debug("New device with id %s created.", device.key().id())
        
        if device.device_token:
            try:
                # register with Urban Airship
                airship = urbanairship.Airship(self.settings.URBANAIRSHIP_APPLICATION_KEY, self.settings.URBANAIRSHIP_MASTER_SECRET)
                airship.register(device.device_token, alias=str(device.key()))
                
                logging.debug("Registered device %s with device token %s at Urban Airship.", device.key().id(), device.device_token)
                
            except urbanairship.AirshipFailure, (status, response):
                logging.error("Could not register device %s with device token %s at Urban Airship: %s (%d)", device.key().id(), device.device_token, response, status)
        
        protocol = self.request._environ['wsgi.url_scheme']
        host = self.request._environ['HTTP_HOST']
        id = device.key().id()
        url = "%s://%s/api/devices/%s?secret=%s" % (protocol, host, id, secret)
        
        return {'id': id, 'url': url, 'secret': secret}


class DeviceResource(Resource):
    
    @environment
    @device_required
    @json
    def put(self, id):
        
        try:
            device = Device.get_by_id(int(id))
        except ValueError:
            device = False
        
        if device:
            
            # device must match authenticated device
            if device.key() == self.get_auth().key():
                
                # see http://code.google.com/p/googleappengine/issues/detail?id=719
                import cgi
                params = cgi.parse_qs(self.request.body)
                
                device.name = params['name'][0]
                
                device_token = params.get('device_token', [])
                if device_token:
                    
                    device.device_token = ''.join(device_token)
                    
                    # register with Urban Airship
                    airship = urbanairship.Airship(self.settings.URBANAIRSHIP_APPLICATION_KEY, self.settings.URBANAIRSHIP_MASTER_SECRET)
                    airship.register(device.device_token, alias=str(device.key()))
                    
                    logging.debug("Registered device %s with device token %s at Urban Airship.", device.key().id(), device.device_token)
                
                device.put()    
            
            else:
                # device does not match authenticated device
                self.error(403)
                self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key().id(), self.get_auth().key().id()))
            
        else:
            # device not found
            self.error(404)
            self.response.out.write("Device %s not found" % id)
    
    @device_required
    @json
    def get(self, id):
        
        try:
            device = Device.get_by_id(int(id))
        except ValueError:
            device = False
        
        if device:
            
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
        
        else:
            # device not found
            self.error(404)
            self.response.out.write("Device %s not found" % id)

