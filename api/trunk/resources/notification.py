import os
import logging
import binascii
import urbanairship
from datetime import datetime
from google.appengine.api import taskqueue
from google.appengine.api.urlfetch import DownloadError
from util import Resource, json, device_required, environment
from models import Device, List
from notifications import Notification, Unread
from resources.list import ListsResource

class ListReadResource(ListsResource):
    
    @environment
    @device_required
    @json
    def post(self, list_id, device_id):
        
        try:
            list = List.get_by_id(int(list_id))
        except ValueError:
            list = False
        
        if list:
            
            # authenticated device must have access to list
            if self.has_access(list):
                
                try:
                    device = Device.get_by_id(int(device_id))
                except ValueError:
                    device = False
                
                if device:
                    
                    for x in list.listdevice_set.filter('device = ', device):
                        x.read = datetime.now()
                        x.unread = 0
                        x.put()
                    
                    # recollect unread count
                    taskqueue.add(url='/api/lists/%s/unread' % list.key().id(), headers={'Environment': self.environment})
                    
                    return {'list': list.key().id(), 'device': device.key().id()}
                    
                else:
                    # device not found
                    self.error(400)
                    self.response.out.write("Device %s not found" % device_id)
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % list_id)

class ListUnreadResource(ListsResource):
    
    def post(self, id):
        
        try:
            list = List.get_by_id(int(id))
        except ValueError:
            list = False
        
        if list:
            
            for x in list.listdevice_set:
                
                # update device unread
                device = x.device
                count = 0
                for y in device.listdevice_set.filter('deleted != ', True):
                    if y.list.modified > y.read:
                        count += 1
                device.unread = count
                device.put()
        
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % id)


class ListPushResource(ListsResource):
    
    @environment
    @device_required
    @json
    def post(self, list_id, device_id):
        
        try:
            list = List.get_by_id(int(list_id))
        except ValueError:
            list = False
        
        if list:
            
            # authenticated device must have access to list
            if self.has_access(list):
                
                try:
                    exclude = Device.get_by_id(int(device_id))
                except ValueError:
                    exclude = False
                
                if exclude:
                    
                    devices = []
                    airship = urbanairship.Airship(self.settings.URBANAIRSHIP_APPLICATION_KEY, self.settings.URBANAIRSHIP_MASTER_SECRET)
                    
                    log = list.get_log(list.pushed)
                    
                    notification = Notification(log)
                    message = notification.get_message()
                    
                    for x in list.listdevice_set.filter('device != ', exclude):
                        if x.device.device_token:
                            
                            unread = x.device.unread
                            
                            payload = {'badge': unread}
                            if message:
                                payload['alert'] = message
                                payload['lightning_list'] = list.key().id()
                            
                            try:
                                # push notification and unread count to Urban Airship
                                airship.push({'aps': payload}, device_tokens=[x.device.device_token])
                                
                                logging.debug("Pushed '%s' (%s) to device %s with device token '%s'.", message, unread, x.device.key().id(), x.device.device_token)
                                
                                devices.append(x.device)
                            
                            except DownloadError, e:
                                logging.error("Unable to push '%s' (%s) to device %s with device token '%s' at Urban Airship: %s", message, unread, x.device.key().id(), x.device.device_token, e)
                            
                            except urbanairship.AirshipFailure, (status, response):
                                logging.error("Unable to push '%s' (%s) to device %s with device token '%s' at Urban Airship: %s (%d)", message, unread, x.device.key().id(), x.device.device_token, response, status)
                    
                    list.pushed = datetime.now()
                    
                    return {'devices': [device.key().id() for device in devices]}
                    
                else:
                    # device to exclude not found
                    self.error(400)
                    self.response.out.write("Device to exclude %s not found" % device_id)
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % list_id)
    
