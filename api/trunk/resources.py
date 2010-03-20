import logging
import os
import binascii
import re
from datetime import datetime
from urlparse import urlparse, parse_qs
from google.appengine.ext import webapp
from google.appengine.ext import db
from google.appengine.api import memcache
from google.appengine.datastore import entity_pb
from django.utils import simplejson
from models import Device, List, Item

class Resource(webapp.RequestHandler):
    
    def get_device(self):
        
        try:
            # authenticate client with device header
            header = urlparse(self.request.headers["Device"])
            id = re.compile(r'^/api/devices/(.*)$').match(header.path).group(1)
            secret = parse_qs(header.query)['secret'][0]
            
            device = Device.get_by_id(int(id))
            if device.secret == secret:
                return device
            
        except KeyError, IndexError:
            pass
    
    def require_device(self):
    
        device = self.get_device()
        
        if not device:
            # authentication failed
            self.error(401)
            self.response.out.write("No device header found!")
            return False
        
        return device


class DevicesResource(Resource):
    
    def post(self):
        
        # generate random secret
        secret = binascii.hexlify(os.urandom(64))
        
        device = Device(name=self.request.get('name'), identifier=self.request.get('identifier'), secret=secret)
        
        device.put()
        
        host = self.request._environ['HTTP_HOST']
        id = device.key().id()
        url = "http://%s/api/devices/%s?secret=%s" % (host, id, secret)
        
        self.response.out.write(simplejson.dumps({'id': id, 'url': url, 'secret': secret}))


class DeviceResource(Resource):
    
    def put(self, id):
        
        # require device
        auth = self.require_device()
        if auth:
            
            device = Device.get_by_id(int(id))
            
            # device must match authenticated device
            if device.key() == auth.key():
                
                device.name = self.request.get('name')
                device.put()
            
            else:
                # device does not match authenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match device %s" % (owner.key()), device.key())
    
    def get(self, id):
        
        # check for authentication
        auth = self.require_device()
        if auth:
            
            device = Device.get_by_id(int(id))
            
            # device must match authenticated device
            if device.key() == auth.key():
                
                host = self.request._environ['HTTP_HOST']
                id = device.key().id()
                secret = device.secret
                url = u"http://%s/api/devices/%s?secret=%s" % (host, id, secret)
                
                self.response.out.write(simplejson.dumps({'id': id, 'url': url, 'secret': secret}))
                
            else:
                # device does not match authenticated device
                self.error(403)
                self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key(), auth.key()))


class ListsResource(Resource):
    
    def post(self):
        
        # require device
        auth = self.require_device()
        if auth:
            
            # owner must match authenticated device
            owner = Device.get_by_id(int(self.request.get('owner')))
            if owner.key() == auth.key():
                
                list = List(title=self.request.get('title'), owner=owner)
                list.put()
                
                host = self.request._environ['HTTP_HOST']
                id = list.key().id()
                url = "http://%s/api/lists/%s" % (host, id)
                
                self.response.out.write(simplejson.dumps({'id': id, 'url': url, 'title': list.title, 'owner': list.owner.key().id()}))
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match authenticated device %s" % (owner.key(), auth.key()))


class ItemsResource(Resource):
    
    def post(self):
        
        item = Item()
        item.value = self.request.get('value')
        item.put()
        
        host = self.request._environ['HTTP_HOST']
        id = item.key().id()
        self.response.out.write("http://%s/api/items/%s" % (host, id))

class ItemResource(Resource):

    def get(self, id):
        
        self.response.headers['Content-Type'] = 'text/plain'
        
        item = memcache.get("item-" + id)
        if item:
            item = db.model_from_protobuf(entity_pb.EntityProto(item))
        else:
            item = Item.get_by_id(int(id))
            if not memcache.set("item-" + id, db.model_to_protobuf(item).Encode()):
                logging.error("Memcache set failed.")
        
        self.response.out.write(item.value)

    def put(self, id):
        item = Item.get_by_id(int(id))
        item.value = self.request.get('value')
        item.put()
        memcache.set("item-" + id, db.model_to_protobuf(item).Encode())

