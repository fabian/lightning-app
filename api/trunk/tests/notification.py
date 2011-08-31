import unittest

import notifications

class ListToTextTest(unittest.TestCase):

    def test_empty(self):
        self.assertEqual('', notifications.list_to_text([]))

    def test_one(self):
        self.assertEqual('Foo', notifications.list_to_text(['Foo']))

    def test_two(self):
        self.assertEqual('Bar and Foo', notifications.list_to_text(['Bar', 'Foo']))

    def test_more(self):
        self.assertEqual('Foo, Bar and Test', notifications.list_to_text(['Foo', 'Bar', 'Test']))
