from google.appengine.ext import db

# http://code.google.com/appengine/articles/modeling.html

class Device(db.Model):
    name = db.StringProperty()
    identifier = db.StringProperty(required=True) # UDID for iPhone
    device_token = db.StringProperty()
    secret = db.StringProperty(required=True) # random, needed to verify udid
    registered = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class List(db.Model):
    title = db.StringProperty(required=True)
    shared = db.BooleanProperty(default=False, required=True)
    token = db.StringProperty(required=True) # random, gets sent per email with the id
    deleted = db.BooleanProperty()
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True)
    
    def has_access(self, device):
        # device must be in device list
        for x in self.listdevice_set:
            if x.device.key() == device.key():
                return x
        return False
    
    def get_log(self, device, since):
        query = Log.all().filter('list =', self).filter('device =', device).filter('happened > ', since).order('happened')
        return query

class Item(db.Model):
    value = db.StringProperty(required=True)
    list = db.ReferenceProperty(List, required=True)
    done = db.BooleanProperty(default=False, required=True)
    deleted = db.BooleanProperty(default=False, required=True)
    added = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True)

class Log(db.Model):
    device = db.ReferenceProperty(Device, required=True)
    item = db.ReferenceProperty(Item, required=True)
    list = db.ReferenceProperty(List, required=True)
    action = db.StringProperty(choices=('added', 'modified', 'completed', 'deleted'), required=True)
    happened = db.DateTimeProperty(required=True, auto_now_add=True)
    old = db.StringProperty()

class ListDevice(db.Model):
    list = db.ReferenceProperty(List, required=True)
    device = db.ReferenceProperty(Device, required=True)
    permission = db.StringProperty(default='guest', required=True, choices=set(['owner', 'guest']))
    deleted = db.BooleanProperty(default=False, required=True)
    read = db.DateTimeProperty(required=True, auto_now_add=True) # last time the list was marked as read
    pushed = db.DateTimeProperty(required=True, auto_now_add=True) # last time the list was pushed by this device
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)
