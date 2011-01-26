
def list_to_text(list):
    """
    >>> list_to_text(['a', 'b', 'c'])
    'a, b and c'
    >>> list_to_text(['a', 'b'])
    'a and b'
    >>> list_to_text(['a'])
    'a'
    >>> list_to_text([])
    ''
    """
    if len(list) == 0: return ""
    if len(list) == 1: return list[0]
    return "%s and %s" % (", ".join([i for i in list][:-1]), list[-1])


class Notification:
    """
    Concats multiple log entries to one message.
    """
    
    def __init__(self, logs, device, since):
        self.logs = logs
        
        items = {}
        for log in self.logs:
            
            if log.happened < since:
                continue # ignore old entries
            
            if log.device.key() == device.key():
                continue # ignore entries of the device itself
            
            id = log.item.key().id()
            if not items.has_key(id):
                items[id] = {}
            
            items[id][log.action] = log
        
        added = []
        modified = []
        deleted = []
        for value in items.values():
            
            if value.has_key('added') and not value.has_key('deleted'):
                added.append(value['added'].item.value)
            
            if value.has_key('modified') and not value.has_key('added') and not value.has_key('deleted'):
                modified.append("%s to %s" % (value['modified'].old, value['modified'].item.value))
                
            if value.has_key('deleted') and not value.has_key('added'):
                deleted.append(value['deleted'].old)
        
        self.unread = 0
        
        messages = []
        if added:
            messages.append("Added %s." % list_to_text(added))
            self.unread += len(added)
        if modified:
            messages.append("Changed %s." % list_to_text(modified))
            self.unread += len(modified)
        if deleted:
            messages.append("Deleted %s." % list_to_text(deleted))
        
        self.message = ' '.join(messages)
    
    def get_message(self):
        return self.message
    
    def get_unread(self):
        return self.unread


class Unread:

    def __init__(self, list):
        self.list = list
    
    def collect(self):
        
        # get all logs needed for notification
        eldest = min(x.read for x in self.list.listdevice_set)
        log = self.list.get_log(eldest)
        
        for x in self.list.listdevice_set:
            
            notification = Notification(log, x.device, x.read)
            
            x.unread = notification.get_unread()
            x.notification = notification.get_message()
            x.put()
            
            # update device unread
            device = x.device
            unread = 0
            for y in device.listdevice_set.filter('deleted != ', True):
                unread += y.unread
            device.unread = unread
            device.put()
