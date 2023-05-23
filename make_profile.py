import argparse
import logging

from components.browser import Browser, get_browsers_classes_by_name

def make_profile():
  log_format = '%(asctime)s: %(message)s'
  logging.basicConfig(level=logging.DEBUG, format=log_format)

  parser = argparse.ArgumentParser()
  parser.add_argument('browser', type=str)
  args = parser.parse_args()
  browser_classes = get_browsers_classes_by_name(args.browser)
  for browser_class in browser_classes:
    browser: Browser = browser_class()
    browser.start(use_source_profile=True)

make_profile()
