import os
import logging
import binascii
from datetime import datetime
from google.appengine.api import taskqueue
import urbanairship
import settings
from util import Resource, json, device_required
from models import List, Item, Log

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
        
        try:
            list = List.get_by_id(int(self.request.get('list')))
        except ValueError:
            list = False
        
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
                taskqueue.add(url='/api/lists/%s/unread' % list.key().id())
                
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
    
    @device_required
    @json
    def get(self, id):
        
        try:
            item = Item.get_by_id(int(id))
        except ValueError:
            item = False
        
        if item:
            if self.has_access(item):
                
                return {'id': item.key().id(), 'url': self.url(item), 'value': item.value, 'done': item.done}
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)
    
    @device_required
    @json
    def put(self, id):
        
        try:
            item = Item.get_by_id(int(id))
        except ValueError:
            item = False
        
        if item:
            if self.has_access(item):
                
                old = item.value
                
                # see http://code.google.com/p/googleappengine/issues/detail?id=719
                import cgi
                params = cgi.parse_qs(self.request.body)
                
                modified = datetime.strptime(params['modified'][0], self.DATE_FORMAT)
                if (item.modified < modified):
                    
                    item.value = params['value'][0]
                    item.done = (params['done'][0] == "1")
                    item.modified = modified
                    item.put()
                    
                    # log action for notification
                    log = Log(device=self.get_auth(), item=item, list=item.list, action='modified', old=old)
                    log.put()
                    taskqueue.add(url='/api/lists/%s/unread' % item.list.key().id())
                    
                    return {'id': id, 'url': self.url(item), 'value': item.value, 'done': item.done, 'modified': item.modified.strftime(self.DATE_FORMAT)}
                    
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
        
        try:
            item = Item.get_by_id(int(id))
        except ValueError:
            item = False
        
        if item:
            if self.has_access(item):
            
                item.deleted = True
                item.put()
                
                # log action for notification
                log = Log(device=self.get_auth(), item=item, list=item.list, action='deleted', old=item.value)
                log.put()
                taskqueue.add(url='/api/lists/%s/unread' % item.list.key().id())
                
                return {}
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)

