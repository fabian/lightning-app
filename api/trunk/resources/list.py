import os
import logging
import binascii
from datetime import datetime
import urbanairship
from util import Resource, json, device_required
from models import ListDevice, Device, List, Item

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
                shared = (self.request.get('shared') == "1")
                
                list = List(title=self.request.get('title'), token=token, shared=shared, modified=datetime.now())
                list.put()
                
                listdevice = ListDevice(list=list, device=owner, permission='owner')
                listdevice.put()
                
                logging.debug("Device %s created list with id %s and title %s. Device list id is %s.", owner.key().id(), list.key().id(), list.title, listdevice.key().id())
                
                protocol = self.request._environ['wsgi.url_scheme']
                host = self.request._environ['HTTP_HOST']
                id = list.key().id()
                url = "%s://%s/api/lists/%s" % (protocol, host, id)
                
                return {'id': id, 'url': url, 'title': list.title, 'shared': list.shared, 'token': token}
            
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
        
        if list:
            
            # device must match authenticated device
            if self.has_access(list):
                
                # see http://code.google.com/p/googleappengine/issues/detail?id=719
                import cgi
                params = cgi.parse_qs(self.request.body)
                
                list.title = params['title'][0]
                
                try:
                	list.shared = (params['shared'][0] == "1")
                except KeyError:
                	pass # don't update shared then
                
                list.put()
                
                return {'id': id, 'url': self.url(list), 'title': list.title, 'shared': list.shared}
        
        else:
            # list not found
            self.error(404)
            self.response.out.write("List %s not found" % id)
    
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
                        'modified': item.modified.strftime(self.DATE_FORMAT), 
                        'done': item.done, 
                    })
                
                id = list.key().id()
                url = self.url(list)
                title = list.title
                
                return {'id': id, 'url': url, 'title': title, 'shared': list.shared, 'items': items}
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)


class DeviceListsResource(ListsResource):
    
    @device_required
    @json
    def get(self, device_id):
        
        # device must match authenticated device
        try:
            device = Device.get_by_id(int(device_id))
        except ValueError:
            device = False
        
        if device:
            if device.key() == self.get_auth().key():
                lists = []
                
                for x in device.listdevice_set:
                    
                    list = x.list
                    count = Item.all().filter('list =', list.key()).count()
                    lists.append({
                        'id': list.key().id(), 
                        'url': self.url(list), 
                        'title': list.title, 
                        'token': list.token, 
                        'count': count, 
                    })
                
                return {'lists': lists}
            
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key().id(), self.get_auth().key().id()))
        else:
            # device for guest not found
            self.error(404)
            self.response.out.write("Can't get device %s" % device_id)


class DeviceListResource(ListsResource):
    
    @device_required
    @json
    def put(self, device_id, list_id):
        
        # device must match authenticated device
        try:
            device = Device.get_by_id(int(device_id))
        except ValueError:
            device = False
        
        if device:
            if device.key() == self.get_auth().key():
                
                try:
                    list = List.get_by_id(int(list_id))
                except ValueError:
                    list = False
                
                if list:
                    
                    # see http://code.google.com/p/googleappengine/issues/detail?id=719
                    import cgi
                    params = cgi.parse_qs(self.request.body)
                    
                    token = params['token'][0]
                    
                    # token must match
                    if list.token == token:
                        
                        listdevice = ListDevice(list=list, device=device)
                        listdevice.put()
                        
                        logging.debug("Device %s added to list with id %s for list %s.", device.key().id(), listdevice.key().id(), list.key().id())
                        
                        protocol = self.request._environ['wsgi.url_scheme']
                        host = self.request._environ['HTTP_HOST']
                        url = "%s://%s/api/devices/%s/lists/%s" % (protocol, host, device.key().id(), list.key().id())
                        
                        return {'url': url, 'list': listdevice.list.key().id(), 'device': listdevice.device.key().id()}
                    
                    else:
                        # token doesn't match
                        self.error(403)
                        self.response.out.write("Token %s doesn't match token for list %s" % (token, list.key().id()))
                else:
                    # list not found
                    self.error(404)
                    self.response.out.write("Can't get list with id %s" % list_id)
            else:
                # owner does not match autenticated device
                self.error(403)
                self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key().id(), self.get_auth().key().id()))
        else:
            # device for owner not found
            self.error(404)
            self.response.out.write("Can't get device with id %s" % device_id)
