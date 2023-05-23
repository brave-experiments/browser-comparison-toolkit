import argparse

from components.browser import Browser, get_browsers_classes_by_name

def make_profile():
  parser = argparse.ArgumentParser()
  parser.add_argument('browser', type=str)
  args = parser.parse_args()
  browser_classes = get_browsers_classes_by_name(args.browser)
  for browser_class in browser_classes:
    browser: Browser = browser_class()
    browser.start(use_source_profile=True)

make_profile()
