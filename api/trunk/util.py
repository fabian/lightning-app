import wsgiref.util

def device_required(handler_method):
    
    def check_device(self, *args):
        print self.request.uri
        handler_method(self, *args)
    return check_device
