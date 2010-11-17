from google.appengine.ext import db

# http://code.google.com/appengine/articles/modeling.html

class Device(db.Model):
    name = db.StringProperty()
    identifier = db.StringProperty(required=True) # UDID for iPhone
    device_token = db.StringProperty(required=True)
    secret = db.StringProperty(required=True) # random, needed to verify udid
    unread = db.IntegerProperty(default=0, required=True) # unread items
    registered = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class List(db.Model):
    title = db.StringProperty(required=True)
    shared = db.BooleanProperty(default=False, required=True)
    token = db.StringProperty(required=True) # random, gets sent per email with the id
    deleted = db.BooleanProperty()
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)
    
    def has_access(self, device):
        # device must be in device list
        for x in self.listdevice_set:
            if x.device.key() == device.key():
                return True
        return False
    
    def get_log(self, since):
        query = Log.all().filter('list =', self).order('happened')
        if since:
            query.filter('happened > ', since)
        return query

class Item(db.Model):
    value = db.StringProperty(required=True)
    list = db.ReferenceProperty(List, required=True)
    deleted = db.BooleanProperty()
    added = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True)

class Log(db.Model):
    device = db.ReferenceProperty(Device, required=True)
    item = db.ReferenceProperty(Item, required=True)
    list = db.ReferenceProperty(List, required=True)
    action = db.StringProperty(choices=('added', 'modified', 'deleted'), required=True)
    happened = db.DateTimeProperty(required=True, auto_now_add=True)
    old = db.StringProperty()

class ListDevice(db.Model):
    list = db.ReferenceProperty(List, required=True)
    device = db.ReferenceProperty(Device, required=True)
    permission = db.StringProperty(default='guest', required=True, choices=set(['owner', 'guest']))
    deleted = db.BooleanProperty(default=False, required=True)
    notification = db.StringProperty()
    unread = db.IntegerProperty(default=0, required=True)
    read = db.DateTimeProperty(required=True, auto_now_add=True) # last time the list was marked as read
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)
