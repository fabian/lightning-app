
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
        
        added = []
        modified = []
        deleted = []
        for log in self.logs:
            if log.action == 'added':
                added.append(log.item.value)
            elif log.action == 'modified':
                modified.append("%s to %s" % (log.old, log.item.value))
            elif log.action == 'deleted':
                deleted.append(log.old)
        
        messages = []
        if added:
            messages.append("Added %s." % list_to_text(added))
        if modified:
            messages.append("Changed %s." % list_to_text(modified))
        if deleted:
            messages.append("Deleted %s." % list_to_text(deleted))
        
        return ' '.join(messages)

