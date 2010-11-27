import os
import logging
import binascii
import urbanairship
import settings
from util import Resource, json, device_required
from models import Device, List
from notifications import Unread
from resources.list import ListsResource

class ListUnreadResource(ListsResource):
    
    def post(self, id):
        
        try:
            list = List.get_by_id(int(id))
        except ValueError:
            list = False
        
        if list:
            
            u = Unread(list)
            u.collect()
        
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)


class ListPushResource(ListsResource):
    
    @device_required
    @json
    def post(self, id):
        
        try:
            list = List.get_by_id(int(id))
        except ValueError:
            list = False
        
        if list:
            
            # authenticated device must have access to list
            if self.has_access(list):
                
                try:
                    exclude = Device.get_by_id(int(self.request.get('exclude')))
                except ValueError:
                    exclude = False
                
                if exclude:
                    
                    devices = []
                    airship = urbanairship.Airship(settings.URBANAIRSHIP_APPLICATION_KEY, settings.URBANAIRSHIP_MASTER_SECRET)
                    
                    for x in list.listdevice_set.filter('device != ', exclude):
                        if x.device.device_token:
                            
                            notification = x.notification
                            unread = x.device.unread
                            
                            # push notification and unread count to Urban Airship
                            airship.push({'aps': {'alert': notification, 'badge': unread, 'lightning_list': list.key().id()}}, device_tokens=[x.device.device_token])
                            
                            logging.debug("Pushed '%s' (%s) to device %s with device token %s.", notification, unread, x.device.key().id(), x.device.device_token)
                            
                            devices.append(x.device)
                    
                    return {'devices': [device.key().id() for device in devices]}
                    
                else:
                    # device to exclude not found
                    self.error(400)
                    self.response.out.write("Device to exclude %s not found" % self.request.get('exclude'))
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)
    
