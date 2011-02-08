from util import Resource, json

class PingResource(Resource):
    
    @json
    def get(self):
        
        return {'ping': 'pong'}
