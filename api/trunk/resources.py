import os
import binascii
from google.appengine.ext import webapp
from models import Device, List, Item
from util import Resource, json, device_required


class DevicesResource(Resource):
    
    @json
    def post(self):
        
        # generate random secret
        secret = binascii.hexlify(os.urandom(64))
        
        device = Device(name=self.request.get('name'), identifier=self.request.get('identifier'), secret=secret)
        
        device.put()
        
        host = self.request._environ['HTTP_HOST']
        id = device.key().id()
        url = "http://%s/api/devices/%s?secret=%s" % (host, id, secret)
        
        return {'id': id, 'url': url, 'secret': secret}


class DeviceResource(Resource):
    
    @device_required
    @json
    def put(self, id):
    
        device = Device.get_by_id(int(id))
        
        # device must match authenticated device
        if device.key() == self.get_auth().key():
            
            device.name = self.request.get('name')
            device.put()
        
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("Owner %s doesn't match authenticated device %s" % (owner.key(), self.get_auth().key()))
    
    @device_required
    @json
    def get(self, id):
        
        device = Device.get_by_id(int(id))
        
        # device must match authenticated device
        if device.key() == self.get_auth().key():
            
            host = self.request._environ['HTTP_HOST']
            id = device.key().id()
            secret = device.secret
            url = u"http://%s/api/devices/%s?secret=%s" % (host, id, secret)
            
            return {'id': id, 'url': url, 'secret': secret}
            
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key(), self.get_auth().key()))


class ListsResource(Resource):
    
    def url(self, list):
        host = self.request._environ['HTTP_HOST']
        id = list.key().id()
        url = u"http://%s/api/lists/%s" % (host, id)
        return url
    
    @device_required
    @json
    def post(self):
        
        # owner must match authenticated device
        owner = Device.get_by_id(int(self.request.get('owner')))
        if owner:
            if owner.key() == self.get_auth().key():
                
                list = List(title=self.request.get('title'), owner=owner)
                list.put()
                
                host = self.request._environ['HTTP_HOST']
                id = list.key().id()
                url = "http://%s/api/lists/%s" % (host, id)
                
                return {'id': id, 'url': url, 'title': list.title, 'owner': list.owner.key().id()}
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match authenticated device %s" % (owner.key(), self.get_auth().key()))
        else:
            # device for owner not found
            self.error(404)
            self.response.out.write("Can't get device for owner %s" % self.request.get('owner'))


class DeviceListsResource(ListsResource):
    
    @device_required
    @json
    def get(self, device):
        
        # owner must match authenticated device
        owner = Device.get_by_id(int(device))
        if owner:
            if owner.key() == self.get_auth().key():
                lists = []
                
                for list in List.all().filter('owner =', owner.key()):
                    
                    lists.append({
                        'id': list.key().id(), 
                        'url': self.url(list), 
                        'title': list.title, 
                    })
                
                return {'lists': lists}
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match authenticated device %s" % (owner.key(), self.get_auth().key()))
        else:
            # device for owner not found
            self.error(404)
            self.response.out.write("Can't get device for owner %s" % device)


class ListResource(ListsResource):
    
    @device_required
    @json
    def get(self, id):
        
        # list owner must match authenticated device
        list = List.get_by_id(int(id))
        if list:
            if list.owner.key() == self.get_auth().key():
                items = []
                
                for item in Item.all().filter('list =', list.key()):
                    
                    host = self.request._environ['HTTP_HOST']
                    id = item.key().id()
                    url = "http://%s/api/items/%s" % (host, id)
                    
                    items.append({
                        'id': item.key().id(), 
                        'url': url, 
                        'value': item.value, 
                    })
                
                return {'items': items}
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match authenticated device %s" % (list.owner.key(), self.get_auth().key()))
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)


class ItemsResource(Resource):
    
    @device_required
    @json
    def post(self):
        
        item = Item()
        item.value = self.request.get('value')
        item.put()
        
        host = self.request._environ['HTTP_HOST']
        id = item.key().id()
        self.response.out.write("http://%s/api/items/%s" % (host, id))

class ItemResource(Resource):
    
    def url(self, item):
        host = self.request._environ['HTTP_HOST']
        id = item.key().id()
        url = u"http://%s/api/items/%s" % (host, id)
        return url
    
    @device_required
    @json
    def get(self, id):
    
        # owner must match authenticated device
        item = Item.get_by_id(int(id))
        if item.list.owner.key() == self.get_auth().key():
            
            return {'id': item.key().id(), 'url': self.url(item), 'value': item.value}
            
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("List owner %s of item doesn't match authenticated device %s" % (item.list.owner.key(), self.get_auth().key()))

    @device_required
    def put(self, id):
        
        # owner must match authenticated device
        item = Item.get_by_id(int(id))
        if item.list.owner.key() == self.get_auth().key():
            
            item.value = self.request.get('value')
            item.put()
            
            return {'id': id, 'url': self.url(item), 'value': item.value}
            
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("List owner %s of item doesn't match authenticated device %s" % (item.list.owner.key(), self.get_auth().key()))

