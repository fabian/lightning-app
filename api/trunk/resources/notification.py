import os
import logging
import binascii
import urbanairship
from datetime import datetime
from google.appengine.api import taskqueue
from google.appengine.api.urlfetch import DownloadError
from util import Resource, json, device_required, environment
from models import Device, List
from notifications import Notification
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
                        x.put()
                    
                    return {'list': list.key().id(), 'device': device.key().id()}
                    
                else:
                    # device not found
                    self.error(400)
                    self.response.out.write("Device %s not found" % device_id)
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % list_id)


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
                    device = Device.get_by_id(int(device_id))
                except ValueError:
                    device = False
                
                if device:
                    
                    # device must match authenticated device
                    if device.key() == self.get_auth().key():
                        
                        devicelist = list.has_access(device)
                        
                        devices = []
                        airship = urbanairship.Airship(self.settings.URBANAIRSHIP_APPLICATION_KEY, self.settings.URBANAIRSHIP_MASTER_SECRET)
                        
                        log = list.get_log(device, devicelist.pushed)
                        
                        notification = Notification(log)
                        message = notification.get_message()
                        
                        for x in list.listdevice_set.filter('device != ', device):
                            if x.device.device_token:
                                
                                # unread count
                                count = 0
                                for y in x.device.listdevice_set.filter('deleted != ', True):
                                    if y.list.modified > y.read:
                                        count += 1
                                
                                payload = {'badge': count}
                                if message:
                                    payload['alert'] = message
                                    payload['lightning_list'] = list.key().id()
                                
                                try:
                                    # push notification and unread count to Urban Airship
                                    airship.push({'aps': payload}, device_tokens=[x.device.device_token])
                                    
                                    logging.debug("Pushed '%s' (%s) to device %s with device token '%s'.", message, count, x.device.key().id(), x.device.device_token)
                                    
                                    devices.append(x.device)
                                
                                except DownloadError, e:
                                    logging.error("Unable to push '%s' (%s) to device %s with device token '%s' at Urban Airship: %s", message, count, x.device.key().id(), x.device.device_token, e)
                                
                                except urbanairship.AirshipFailure, (status, response):
                                    logging.error("Unable to push '%s' (%s) to device %s with device token '%s' at Urban Airship: %s (%d)", message, count, x.device.key().id(), x.device.device_token, response, status)
                        
                        devicelist.pushed = datetime.now()
                        devicelist.put()
                        
                        return {'devices': [device.key().id() for device in devices]}
                    
                    else:
                        # device does not match authenticated device
                        self.error(403)
                        self.response.out.write("Device %s doesn't match authenticated device %s" % (device.key().id(), self.get_auth().key().id()))
                
                else:
                    # device to push not found
                    self.error(404)
                    self.response.out.write("Device to push %s not found" % device_id)
            
        else:
            # list not found
            self.error(404)
            self.response.out.write("Can't get list with id %s" % list_id)
    
