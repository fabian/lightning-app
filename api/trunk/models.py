from google.appengine.ext import db
from notifications import Notification

# http://code.google.com/appengine/articles/modeling.html

class Device(db.Model):
    name = db.StringProperty()
    identifier = db.StringProperty(required=True) # UDID for iPhone
    secret = db.StringProperty(required=True) # random, needed to verify udid
    unread = db.ListProperty(db.Key) # unread items
    registered = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)


class List(db.Model):
    title = db.StringProperty(required=True)
    owner = db.ReferenceProperty(Device, required=True)
    deleted = db.BooleanProperty()
    unread = db.IntegerProperty(default=0, required=True)
    notified = db.DateTimeProperty() # last time a notification was sent
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)
    
    def get_log(self, since):
        query = Log.all().filter('list =', self)
        if since:
            query.filter('happened > ', since)
        return query
    
    def get_notification(self):
        log = self.get_log(self.notified)
        notification = Notification(log)
        return notification.get_message()

class Item(db.Model):
    value = db.StringProperty(required=True)
    list = db.ReferenceProperty(List, required=True)
    deleted = db.BooleanProperty()
    added = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class Log(db.Model):
    device = db.ReferenceProperty(Device, required=True)
    item = db.ReferenceProperty(Item, required=True)
    list = db.ReferenceProperty(List, required=True)
    action = db.StringProperty(choices=('added', 'modified', 'deleted'), required=True)
    happened = db.DateTimeProperty(required=True, auto_now_add=True)
    old = db.StringProperty()

class Group(db.Model):
    name = db.StringProperty(required=True) # group name
    lists = db.ListProperty(db.Key)
    token = db.StringProperty(required=True) # random, gets sent per email with the id
    deleted = db.BooleanProperty()
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class SharedList(db.Model):
    group = db.ReferenceProperty(Group, required=True)
    list = db.ReferenceProperty(List, required=True)
    guest = db.ReferenceProperty(Device, required=True)
    unread = db.IntegerProperty(default=0, required=True)
    deleted = db.BooleanProperty(default=False, required=True)
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)
