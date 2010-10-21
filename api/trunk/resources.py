import logging
import os
import binascii
from datetime import datetime
from google.appengine.ext import webapp
import urbanairship
import settings
from models import Device, List, Item, Log
from util import Resource, json, device_required

class DevicesResource(Resource):
    
    @json
    def post(self):
        
        # generate random secret
        secret = binascii.hexlify(os.urandom(64))
        
        device = Device(name=self.request.get('name'), identifier=self.request.get('identifier'), device_token=self.request.get('device_token'), secret=secret)
        
        device.put()
        
        logging.debug("New device with id %s created", device.key().id())
        
        # register with Urban Airship
        airship = urbanairship.Airship(settings.URBANAIRSHIP_APPLICATION_KEY, settings.URBANAIRSHIP_MASTER_SECRET)
        airship.register(device.device_token, alias=str(device.key()))
        
        logging.debug("Registered device %s with device token %s at Urban Airship", device.key().id(), device.device_token)
        
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
            
            device.name = self.request.get('name')
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
        owner = Device.get_by_id(int(self.request.get('owner')))
        if owner:
            if owner.key() == self.get_auth().key():
                
                # generate random token
                token = binascii.hexlify(os.urandom(8))
                
                list = List(title=self.request.get('title'), owner=owner, token=token)
                list.put()
                
                logging.debug("Device %s created list with id %s", owner.key().id(), list.key().id())
                
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
                        'unread': list.unread, 
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


class ListResource(ListsResource):
    
    @device_required
    @json
    def put(self, id):
    
        list = List.get_by_id(int(id))
        
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
        
        list = List.get_by_id(int(id))
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
                unread = list.unread
                
                return {'id': id, 'url': url, 'title': title, 'unread': unread, 'items': items}
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)


class ListPushResource(ListsResource):
    
    @device_required
    @json
    def post(self, id):
    
        list = List.get_by_id(int(id))
        
        # authenticated device must have access to list
        if self.has_access(list):
            
            exclude = Device.get_by_id(int(self.request.get('exclude')))
            
            if exclude:
                devices = []
                
                # also notify owner of list if he is not excluded
                if list.owner.key() != exclude.key():
                    devices.append(list.owner)
                
                for shared in list.sharedlist_set.filter('guest != ', exclude):
                    devices.append(shared.guest)
                
                airship = urbanairship.Airship(settings.URBANAIRSHIP_APPLICATION_KEY, settings.URBANAIRSHIP_MASTER_SECRET)
                
                notification = list.get_notification()
                for device in devices:
                    unread = 0
                    for list in device.list_set.filter('deleted != ', True):
                        unread += list.unread
                    for shared in device.sharedlist_set.filter('deleted != ', True):
                        unread += shared.unread
                    
                    # push notification and unread count to Urban Airship
                    airship.push({'aps': {'alert': notification, 'badge': unread}}, device_tokens=[device.device_token])
                
                list.notified = datetime.now()
                list.put()
                
                return {'devices': [device.key().id() for device in devices], 'notification': notification}
                
            else:
                # device to exclude not found
                self.error(400)
                self.response.out.write("Device to exclude %s not found" % self.request.get('exclude'))


class ItemsResource(Resource):
    
    def has_access(self, item):
        
        device = self.get_auth()
        
        # authenticated device must have access to item list
        if not item.list.has_access(device):
            
            self.error(403)
            self.response.out.write("Authenticated device %s has no access to list of item" % device.key().id())
            
            return False
        
        else:
            return True
    
    def url(self, item):
        protocol = self.request._environ['wsgi.url_scheme']
        host = self.request._environ['HTTP_HOST']
        id = item.key().id()
        url = u"%s://%s/api/items/%s" % (protocol, host, id)
        return url
    
    @device_required
    @json
    def post(self):
        
        list = List.get_by_id(int(self.request.get('list')))
        if list:
            
            modified = datetime.now()
            item = Item(value=self.request.get('value'), list=list, modified=modified)
            
            # authenticated device must have access to item
            if self.has_access(item):
                
                # access granted, save item
                item.put()
                
                # log action for notification
                log = Log(device=self.get_auth(), item=item, list=list, action='added')
                log.put()
                
                protocol = self.request._environ['wsgi.url_scheme']
                host = self.request._environ['HTTP_HOST']
                id = item.key().id()
                url = "%s://%s/api/items/%s" % (protocol, host, id)
                
                return {'id': id, 'url': url, 'value': item.value, 'list': list.key().id()}
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list %s" % self.request.get('list'))


class ItemResource(ItemsResource):
    
    DATE_FORMAT = "%Y-%m-%d %H:%M:%S"
    
    @device_required
    @json
    def get(self, id):
        
        item = Item.get_by_id(int(id))
        if item:
            if self.has_access(item):
                
                return {'id': item.key().id(), 'url': self.url(item), 'value': item.value}
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)
    
    @device_required
    @json
    def put(self, id):
        
        item = Item.get_by_id(int(id))
        if item:
            if self.has_access(item):
                
                old = item.value
                
                # see http://code.google.com/p/googleappengine/issues/detail?id=719
                import cgi
                params = cgi.parse_qs(self.request.body)
                
                modified = datetime.strptime(params['modified'][0], self.DATE_FORMAT)
                if (item.modified < modified):
                    
                    item.value = params['value'][0]
                    item.modified = modified
                    item.put()
                    
                    # log action for notification
                    log = Log(device=self.get_auth(), item=item, list=item.list, action='modified', old=old)
                    log.put()
                    
                    return {'id': id, 'url': self.url(item), 'value': item.value, 'modified': item.modified.strftime(self.DATE_FORMAT)}
                    
                else:
                    # conflict
                    self.error(409)
                    self.response.out.write("Conflict, has later modification")
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)
    
    @device_required
    def delete(self, id):
        
        item = Item.get_by_id(int(id))
        if item:
            if self.has_access(item):
            
                item.deleted = True
                item.put()
                
                # log action for notification
                log = Log(device=self.get_auth(), item=item, list=item.list, action='deleted', old=item.value)
                log.put()
                
                return {}
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)

