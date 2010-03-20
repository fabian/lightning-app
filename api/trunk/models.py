from google.appengine.ext import db

# http://code.google.com/appengine/articles/modeling.html

class Device(db.Model):
    name = db.StringProperty()
    identifier = db.StringProperty(required=True) # UDID for iPhone
    secret = db.StringProperty(required=True) # random, needed to verify udid
    registered = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class List(db.Model):
    title = db.StringProperty(required=True)
    owner = db.ReferenceProperty(Device, required=True)
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class Item(db.Model):
    value = db.StringProperty(required=True)
    list = db.ReferenceProperty(List, required=True)
    added = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class Invitation(db.Model):
    list = db.ReferenceProperty(List, required=True)
    name = db.StringProperty(required=True) # group name
    token = db.StringProperty(required=True) # random, gets sent per email with the id
    deleted = db.BooleanProperty()
    created = db.DateTimeProperty(required=True, auto_now_add=True)
    modified = db.DateTimeProperty(required=True, auto_now=True)

class SharedList(db.Model):
    invitation = db.ReferenceProperty(Invitation, required=True)
    guest = db.ReferenceProperty(Device, required=True)
    created = db.DateTimeProperty(required=True, auto_now_add=True)
