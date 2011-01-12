import os
import logging
import binascii
import urbanairship
import settings
from util import Resource, json, device_required
from models import Device, List
from notifications import Unread
from resources.list import ListsResource

class PingResource(Resource):
    
    @json
    def get(self):
        
        return {'ping': 'pong'}
