import os
import logging
import binascii
from datetime import datetime
from google.appengine.api import taskqueue
import urbanairship
from util import Resource, json, device_required, environment
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
        host_url = self.request.host_url
        id = item.key().id()
        url = u"%s/api/items/%s" % (host_url, id)
        return url
    
    @environment
    @device_required
    @json
    def post(self):
        
        try:
            list = List.get_by_id(int(self.request.get('list')))
        except ValueError:
            list = False
        
        if list:
            
            item = Item(value=self.request.get('value'), list=list, modified=datetime.now())
            
            # authenticated device must have access to item
            if self.has_access(item):
                
                # access granted, save item
                item.list.modified = item.modified
                item.list.put()
                item.put()
                
                # log action for notification
                log = Log(device=self.get_auth(), item=item, list=list, action='added')
                log.put()
                
                host_url = self.request.host_url
                id = item.key().id()
                url = "%s/api/items/%s" % (host_url, id)
                
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
    
    @environment
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
                    
                    try:
                        item.value = params['value'][0]
                        
                        # log action for notification
                        log = Log(device=self.get_auth(), item=item, list=item.list, action='modified', old=old)
                        log.put()
                        
                    except KeyError:
                        pass # don't update done then
                    
                    try:
                        item.done = (params['done'][0] == "1")
                        
                        # log action for notification
                        log = Log(device=self.get_auth(), item=item, list=item.list, action='completed')
                        log.put()
                        
                    except KeyError:
                        pass # don't update done then
                    
                    item.modified = modified
                    item.list.modified = datetime.now()
                    item.list.put()
                    item.put()
                    
                    return {'id': id, 'url': self.url(item), 'value': item.value, 'done': item.done, 'modified': item.modified.strftime(self.DATE_FORMAT)}
                    
                else:
                    # conflict
                    self.error(409)
                    self.response.out.write("Conflict, has later modification")
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)
    
    @environment
    @device_required
    @json
    def delete(self, id):
        
        try:
            item = Item.get_by_id(int(id))
        except ValueError:
            item = False
        
        if item:
            if self.has_access(item):
            
                item.deleted = True
                item.list.modified = datetime.now()
                item.list.put()
                item.put()
                
                # log action for notification
                log = Log(device=self.get_auth(), item=item, list=item.list, action='deleted', old=item.value)
                log.put()
                
                return {}
            
        else:
            # item not found
            self.error(404)
            self.response.out.write("Item %s not found" % id)

