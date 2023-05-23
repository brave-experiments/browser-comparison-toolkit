import argparse
import logging
import csv
import statistics
from typing import Dict, List
from components.browser import Browser, get_browsers_classes_by_name

from components.memory_measurement import MemoryMeasurement

def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('browser', type=str)
  parser.add_argument('urls_file',
                      type=argparse.FileType('r'),
                      help='File with urls to test')
  parser.add_argument('--connectivity_profile', type=str)
  parser.add_argument('--verbose', action='store_true')
  parser.add_argument('--unsafe', action='store_true')
  parser.add_argument('--repeat', type=int, default=1)
  parser.add_argument('--debug-low-delay', action='store_true')
  parser.add_argument('--output', type=str, default='results.csv')

  args = parser.parse_args()

  log_level = logging.DEBUG if args.verbose else logging.INFO
  log_format = '%(asctime)s: %(message)s'
  logging.basicConfig(level=log_level, format=log_format)


  urls = args.urls_file.readlines()
  test_name = args.urls_file.name
  repeat: int = args.repeat

  with open(args.output, 'w', newline='') as result_file:
    result_writer = csv.writer(result_file, delimiter=',',
                               quotechar='"', quoting=csv.QUOTE_MINIMAL)
    measure = MemoryMeasurement(args.debug_low_delay)
    result_writer.writerow(['Test name', 'Browser', 'Metric_name'] + ['value'] * args.repeat + ['avg', 'stdev'])
    browser_classes = get_browsers_classes_by_name(args.browser)
    for browser_class in browser_classes:
      results: Dict[str, List[float]] = {}
      browser_name: str = ''
      for _ in range(repeat):
        browser: Browser = browser_class()
        browser_name = browser.name()
        metrics = measure.Run(urls, browser, args.unsafe)
        for metric, value in metrics.items():
          if results.get(metric) is None:
            results[metric] = [value]
          else:
            results[metric].append(value)

          logging.info([test_name, browser_name, metrics])
      for metric, values in results.items():
        avg = statistics.fmean(values)
        stdev = statistics.stdev(values) if len(values) > 1 else -1
        result_writer.writerow([test_name, browser_name, metric] + values + [avg, stdev])
main()
