#!/usr/bin/env python

import urllib
import urllib2
import httplib
import datetime
import json

#url = 'http://localhost:8080'
url = 'https://lightning-api.appspot.com'

# create device Marvin and read id
req = urllib2.Request(url + '/api/devices', 'name=Marvin&identifier=101010&device_token=FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660', {'Environment': 'development'})
result = urllib2.urlopen(req)
device = json.loads(result.read())

marvin_id = device['id']
marvin_url = device['url']

print 'Added Marvin with ID %d' % marvin_id


# create device Zem and read id
req = urllib2.Request(url + '/api/devices', 'name=Zem&identifier=010101&device_token=FE66489F304DC75B8D6E8200DFF8A456E8DAEACEC428B427E9518741C92C6660', {'Environment': 'development'})
result = urllib2.urlopen(req)
device = json.loads(result.read())

zem_id = device['id']
zem_url = device['url']

print 'Added Zem with ID %d' % zem_id


# create list
req = urllib2.Request(url + '/api/lists', 'title=Groceries&owner=%d' % marvin_id, {'Device': marvin_url, 'Environment': 'development'})
result = urllib2.urlopen(req)
list = json.loads(result.read())

list_id = list['id']
list_token = list['token']

print 'Created list with ID %d' % list_id


# add Zem to list
req = urllib2.Request(url + '/api/devices/%d/lists/%d' % (zem_id, list_id), 'token=' + list_token, {'Device': zem_url, 'Environment': 'development'})
req.get_method = lambda: 'PUT'
result = urllib2.urlopen(req)

print 'Added Zem to list'


# add item to list
req = urllib2.Request(url + '/api/items', 'value=Juice&list=%d' % list_id, {'Device': marvin_url, 'Environment': 'development'})
result = urllib2.urlopen(req)
item = json.loads(result.read())

item_id = item['id']

print 'Added Juice to list'


# rename item in list
req = urllib2.Request(url + '/api/items/%d' % item_id, 'value=Bread&modified=%s' % datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'), {'Device': marvin_url, 'Environment': 'development'})
req.get_method = lambda: 'PUT'
urllib2.urlopen(req)

print 'Renamed Juice to Milk in list'


# add item to list
req = urllib2.Request(url + '/api/items', 'value=Bread&list=%d' % list_id, {'Device': marvin_url, 'Environment': 'development'})
result = urllib2.urlopen(req)
item = json.loads(result.read())

item_id = item['id']

print 'Added Bread to list'


# remove item to list
req = urllib2.Request(url + '/api/items/%d' % item_id, '', {'Device': marvin_url, 'Environment': 'development'})
req.get_method = lambda: 'DELETE'
urllib2.urlopen(req)

print 'Removed Bread from list'


# push
req = urllib2.Request(url + '/api/lists/%d/devices/%d/push' % (list_id, marvin_id), '', {'Device': marvin_url, 'Environment': 'development'})
result = urllib2.urlopen(req)
print result.read()

print 'Pushed'

