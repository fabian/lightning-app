#!/bin/bash
coverage run tests.py && coverage report && coverage html && open coverage_html_report/index.html
