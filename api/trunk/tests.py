#!/usr/bin/env python

import unittest
import sys
import os

sys.path = sys.path + ['/usr/local/google_appengine', '/usr/local/google_appengine/lib/webob_1_1_1', '/usr/local/google_appengine/lib/yaml/lib', '/usr/local/google_appengine/google/appengine']

from tests.device import *
from tests.item import *
from tests.list import *
from tests.notification import *
from tests.ping import *
from tests.push import *
from tests.read import *
from tests.util import *

if __name__ == "__main__":
    os.environ['APPLICATION_ID'] = 'lightning-app'
    unittest.main()
