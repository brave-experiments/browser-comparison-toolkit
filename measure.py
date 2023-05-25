import argparse
import logging
import csv
import statistics
from typing import Dict, List

from components.browser import get_browsers_classes_by_name
from components.browsertime_measurement import BrowsertimeMeasurement
from components.measurement import MeasurementState
from components.memory_measurement import MemoryMeasurement

def get_measure_by_args(args):
  state = MeasurementState()
  state.low_delays_for_testing = args.low_delays_for_testing
  state.unsafe_use_profiles = args.unsafe_use_profiles
  state.urls = args.urls_file.read().splitlines()

  if args.measure == 'memory':
    return MemoryMeasurement(state)
  if args.measure == 'browsertime':
    return BrowsertimeMeasurement(state)
  raise RuntimeError(f'No measurement {args.measure} found')


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('measure', type=str)
  parser.add_argument('browser', type=str)
  parser.add_argument('urls_file',
                      type=argparse.FileType('r'),
                      help='File with urls to test')
  parser.add_argument('--connectivity_profile', type=str)
  parser.add_argument('--verbose', action='store_true')
  parser.add_argument('--unsafe-use-profiles', action='store_true')
  parser.add_argument('--repeat', type=int, default=1)
  parser.add_argument('--low-delays-for-testing', action='store_true')
  parser.add_argument('--output', type=str, default='results.csv')

  args = parser.parse_args()

  log_level = logging.DEBUG if args.verbose else logging.INFO
  log_format = '%(asctime)s: %(message)s'
  logging.basicConfig(level=log_level, format=log_format)

  measure = get_measure_by_args(args)
  test_name: str = args.urls_file.name
  repeat: int = args.repeat

  with open(args.output, 'w', newline='') as result_file:
    result_writer = csv.writer(result_file, delimiter=',',
                               quotechar='"', quoting=csv.QUOTE_MINIMAL)

    result_writer.writerow(['Test name', 'Browser', 'Metric_name'] + ['value'] * args.repeat + ['avg', 'stdev', 'stdev%'])
    browser_classes = get_browsers_classes_by_name(args.browser)
    for browser_class in browser_classes:
      results: Dict[str, List[float]] = {}
      browser_name: str = ''
      for iteration in range(repeat):
        browser_name = browser_class.name()
        metrics = measure.Run(iteration, browser_class)
        for metric, key, value in metrics:
          metric_name = metric + '_' + key
          if results.get(metric_name) is None:
            results[metric_name] = [value]
          else:
            results[metric_name].append(value)

          if key is not None:
            total_metric_name = f'{metric}_Total'
            if results.get(total_metric_name) is None:
              results[total_metric_name] = []
            if len(results[total_metric_name]) <= iteration:
              results[total_metric_name].append(0)
            results[total_metric_name][-1] += value

        logging.info([test_name, browser_name, metrics])
      for metric, values in results.items():
        avg = statistics.fmean(values)
        stdev = statistics.stdev(values) if len(values) > 1 else 0
        rstdev = stdev / avg if avg > 0 else 0
        result_writer.writerow(
          [test_name, browser_name, metric] + values + [avg, stdev, rstdev])
main()
