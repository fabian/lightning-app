
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
    
    def __init__(self, logs):
        self.logs = logs
    
    def get_message(self):
        
        items = {}
        for log in self.logs:
            
            if not items.has_key(log.item.key()):
                items[log.item.key()] = {}
            
            items[log.item.key()][log.action] = log
        
        added = []
        modified = []
        deleted = []
        for value in items.values():
            
            if value.has_key('added') and not value.has_key('deleted'):
                added.append(value['added'].item.value)
            
            if value.has_key('modified') and not value.has_key('deleted'):
                modified.append("%s to %s" % (value['modified'].old, value['modified'].item.value))
                
            if value.has_key('deleted') and not value.has_key('added'):
                deleted.append(value['deleted'].old)
        
        messages = []
        if added:
            messages.append("Added %s." % list_to_text(added))
        if modified:
            messages.append("Changed %s." % list_to_text(modified))
        if deleted:
            messages.append("Deleted %s." % list_to_text(deleted))
        
        return ' '.join(messages)

