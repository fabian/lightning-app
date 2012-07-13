
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

class History:
    """
    Summarize multiple log entries into added, modified and deleted. Ignoring added and modified items that have already been deleted.
    """
    
    def __init__(self, logs):
        
        items = {}
        for log in logs:
            
            id = Log.item.get_value_for_datastore(log).id()
            if not items.has_key(id):
                items[id] = {}
            
            items[id][log.action] = log
        
        self.added = []
        self.modified = []
        self.completed = []
        self.deleted = []
        for value in items.values():
            
            if value.has_key('added') and not value.has_key('deleted'):
                self.added.append(value['added'].item.value)
            
            if value.has_key('modified') and not value.has_key('added') and not value.has_key('completed') and not value.has_key('deleted'):
                self.modified.append("%s to %s" % (value['modified'].old, value['modified'].item.value))
            
            if value.has_key('completed') and not value.has_key('added') and not value.has_key('deleted'):
                self.completed.append(value['completed'].item.value)
                
            if value.has_key('deleted') and not value.has_key('added'):
                self.deleted.append(value['deleted'].old)
    
    def get_added(self):
        return self.added
    
    def get_modified(self):
        return self.modified
    
    def get_completed(self):
        return self.completed
    
    def get_deleted(self):
        return self.deleted
    

class Notification:
    """
    Concats multiple log entries to one message.
    """
    
    def __init__(self, logs):
        
        history = History(logs)
        
        messages = []
        
        added = history.get_added()
        if added:
            messages.append("Added %s." % list_to_text(added))
        
        completed = history.get_completed()
        if completed:
            messages.append("Completed %s." % list_to_text(completed))
        
        modified = history.get_modified()
        if modified:
            messages.append("Changed %s." % list_to_text(modified))
        
        deleted = history.get_deleted()
        if deleted:
            messages.append("Deleted %s." % list_to_text(deleted))
        
        self.message = ' '.join(messages)
    
    def get_message(self):
        return self.message

