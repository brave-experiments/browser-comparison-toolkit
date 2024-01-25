#!/usr/bin/env python3
# Copyright (c) 2023 The Brave Authors. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at https://mozilla.org/MPL/2.0/.

import argparse
import logging
import csv
import statistics
from typing import Dict, List, Optional, Tuple

from components.browser import get_browser_classes_from_str
from components.measurement import MeasurementState
from components.benchmark_measurement import BenchmarkMeasurement
from components.loading_measurement import LoadingMeasurement
from components.memory_measurement import MemoryMeasurement


def get_measure_by_args(args):
  state = MeasurementState()
  state.low_delays_for_testing = args.low_delays_for_testing
  state.unsafe_use_profiles = args.unsafe_use_profiles
  state.urls = args.urls_file.read().splitlines()

  if args.measure == 'memory':
    return MemoryMeasurement(state)
  if args.measure == 'loading':
    return LoadingMeasurement(state)
  if args.measure == 'benchmarks':
    return BenchmarkMeasurement(state)
  raise RuntimeError(f'No measurement {args.measure} found')


class ResultMap():
  #  Dict[Tuple[metric, key], Dict[browser_name, metric_values]]
  _map: Dict[Tuple[str, Optional[str]], Dict[str, List[float]]] = {}

  def addValue(self, browser_name: str, metric: str, key: Optional[str],
               value: float):
    metric_results = self._map.get((metric, key))
    if metric_results is None:
      metric_results = self._map[(metric, key)] = {}

    values = metric_results.get(browser_name)
    if values is None:
      values = metric_results[browser_name] = []

    values.append(value)

  # Calculate *_Total metrics
  def calc_total_metrics(self):
    total_metrics: Dict[str, Dict[str, List[float]]] = {}

    for (metric, key), results in self._map.items():
      if key is None:
        continue
      total_metric_name = f'{metric}_Total'
      total_per_browser = total_metrics.get(total_metric_name)
      if total_per_browser is None:
        total_per_browser = total_metrics[total_metric_name] = {}
      for browser_name, values in results.items():
        total_values = total_per_browser.get(browser_name)
        if total_values is None:
          total_values = total_per_browser[browser_name] = []

        if len(total_values) < len(values):
          total_values += [0] * (len(values) - len(total_values))
        for index, value in enumerate(values):
          total_values[index] += value

    for (metric, per_browser_map) in total_metrics.items():
      self._map[(metric, None)] = per_browser_map

  def write_csv(self, output_file: str, repeat: int):
    self.calc_total_metrics()
    with open(output_file, 'w', newline='', encoding='utf-8') as result_file:
      result_writer = csv.writer(result_file,
                                 delimiter=',',
                                 quotechar='"',
                                 quoting=csv.QUOTE_NONNUMERIC)
      result_writer.writerow(['Metric_name', 'Browser'] + ['value'] * repeat +
                             ['avg', 'stdev', 'stdev%'])
      for (metric, key), results in self._map.items():
        metric_str = metric + '_' + key if key is not None else metric
        for browser_name, values in results.items():
          avg = statistics.fmean(values)
          stdev = statistics.stdev(values) if len(values) > 1 else 0
          rstdev = stdev / avg if avg > 0 else 0
          result_writer.writerow([metric_str, browser_name] + values +
                                 [avg, stdev, rstdev])


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument('measure', type=str)
  parser.add_argument('browser', type=str)
  parser.add_argument('urls_file',
                      type=argparse.FileType('r', encoding='utf-8'),
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

  browser_classes = get_browser_classes_from_str(args.browser)
  results = ResultMap()

  for browser_class in browser_classes:
    browser_name = browser_class.name()

    for iteration in range(repeat):
      metrics = measure.Run(iteration, browser_class)
      logging.debug([test_name, browser_name, metrics])
      for metric, key, value in metrics:
        results.addValue(browser_name, metric, key, value)
    results.write_csv(args.output, args.repeat)


main()
