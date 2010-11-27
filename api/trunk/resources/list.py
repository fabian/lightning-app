import os
import logging
import binascii
import urbanairship
import settings
from util import Resource, json, device_required
from models import Device, List, Item

class ListsResource(Resource):
    
    def has_access(self, list):
        
        device = self.get_auth()
        
        # authenticated device must have access to list
        if not list.has_access(device):
            
            self.error(403)
            self.response.out.write("Authenticated device %s has no access to list" % device.key().id())
            
            return False
        
        else:
            return True
    
    def url(self, list):
        protocol = self.request._environ['wsgi.url_scheme']
        host = self.request._environ['HTTP_HOST']
        id = list.key().id()
        url = u"%s://%s/api/lists/%s" % (protocol, host, id)
        return url
    
    @device_required
    @json
    def post(self):
        
        # owner must match authenticated device
        try:
            owner = Device.get_by_id(int(self.request.get('owner')))
        except ValueError:
            owner = False
        
        if owner:
            if owner.key() == self.get_auth().key():
                
                # generate random token
                token = binascii.hexlify(os.urandom(8))
                
                list = List(title=self.request.get('title'), owner=owner, token=token)
                list.put()
                
                listdevice = ListDevice(list=list, device=owner)
                listdevice.put()
                
                logging.debug("Device %s created list with id %s and title %s. Device list id is %s.", owner.key().id(), list.key().id(), list.title, listdevice.key().id())
                
                protocol = self.request._environ['wsgi.url_scheme']
                host = self.request._environ['HTTP_HOST']
                id = list.key().id()
                url = "%s://%s/api/lists/%s" % (protocol, host, id)
                
                return {'id': id, 'url': url, 'title': list.title, 'owner': list.owner.key().id(), 'token': token}
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match authenticated device %s" % (owner.key().id(), self.get_auth().key().id()))
        else:
            # device for owner not found
            self.error(404)
            self.response.out.write("Can't get device for owner %s" % self.request.get('owner'))


class ListResource(ListsResource):
    
    @device_required
    @json
    def put(self, id):
        
        try:
            list = List.get_by_id(int(id))
        except ValueError:
            list = False
        
        # device must match authenticated device
        if list.owner.key() == self.get_auth().key():
            
            list.title = self.request.get('title')
            list.put()
        
        else:
            # device does not match authenticated device
            self.error(403)
            self.response.out.write("Owner of list %s doesn't match authenticated device %s" % (list.owner.key().id(), self.get_auth().key().id()))
    
    
    @device_required
    @json
    def get(self, id):
        
        try:
            list = List.get_by_id(int(id))
        except ValueError:
            list = False
        
        if list:
            
            # authenticated device must have access to list
            if self.has_access(list):
                items = []
                
                for item in Item.all().filter('list =', list.key()):
                    
                    protocol = self.request._environ['wsgi.url_scheme']
                    host = self.request._environ['HTTP_HOST']
                    id = item.key().id()
                    url = "%s://%s/api/items/%s" % (protocol, host, id)
                    
                    items.append({
                        'id': item.key().id(), 
                        'url': url, 
                        'value': item.value, 
                    })
                
                id = list.key().id()
                url = self.url(list)
                title = list.title
                
                return {'id': id, 'url': url, 'title': title, 'items': items}
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)


class DeviceListsResource(ListsResource):
    
    @device_required
    @json
    def get(self, device):
        
        # owner must match authenticated device
        try:
            owner = Device.get_by_id(int(device))
        except ValueError:
            owner = False
        
        if owner:
            if owner.key() == self.get_auth().key():
                lists = []
                
                for x in owner.listdevice_set:
                    
                    list = x.list
                    lists.append({
                        'id': list.key().id(), 
                        'url': self.url(list), 
                        'title': list.title, 
                        'unread': x.unread, 
                    })
                
                return {'lists': lists}
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Owner %s doesn't match authenticated device %s" % (owner.key().id(), self.get_auth().key().id()))
        else:
            # device for owner not found
            self.error(404)
            self.response.out.write("Can't get device for owner %s" % device)


class DeviceListResource(ListsResource):
    
    @device_required
    @json
    def put(self, list_id, device_id):
        
        try:
            list = List.get_by_id(int(list_id))
        except ValueError:
            list = False
        # TODO check if list exists
    
        # guest must match authenticated device
        try:
            guest = Device.get_by_id(int(device_id))
        except ValueError:
            exclude = False
        
        if guest:
            if guest.key() == self.get_auth().key():
                
                token = self.request.get('token')
                
                # token must match
                if list.token == token:
                    
                    listdevice = ListDevice(list=list, device=owner)
                    listdevice.put()
                    
                    logging.debug("Device %s added to list with id %s for list %s.", guest.key().id(), listdevice.key().id(), list.key().id())
                    
                    protocol = self.request._environ['wsgi.url_scheme']
                    host = self.request._environ['HTTP_HOST']
                    id = shared.key().id()
                    url = "%s://%s/api/shared_lists/%s" % (protocol, host, id)
                    
                    return {'id': id, 'url': url, 'list': shared.list.key().id(), 'guest': shared.guest.key().id()}
                
                else:
                    # token doesn't match
                    self.error(403)
                    self.response.out.write("Token %s doesn't match token for list %s" % (token, list.key().id()))
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Guest %s doesn't match authenticated device %s" % (guest.key().id(), self.get_auth().key().id()))
        else:
            # device for owner not found
            self.error(404)
            self.response.out.write("Can't get device for guest %s" % self.request.get('guest'))
