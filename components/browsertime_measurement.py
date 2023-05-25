import json
import os
import platform
import re
import logging
import subprocess
import math
import time
import psutil
import tempfile

from components.browser import Browser
from components.measurement import Measurement
from typing import List, Optional, Tuple, Type

class BrowsertimeMeasurement(Measurement):
  def Run(self, iteration: int, browser_class: Type[Browser]) -> List[Tuple[str, str, float]]:
    urls = self.state.urls
    results:List[Tuple[str, str, float]] = []

    for i in range(len(urls)):
      browser = browser_class()
      browser.prepare_profile(self.state.unsafe_use_profiles)
      url = urls[i]
      result_dir = f'browsertime/{browser.name()}/{i}_{url}/{iteration}/'
      args = ['browsertime',
              '-b', browser.browsertime_binary,
              '-n', '1',
              '--useSameDir',
              '--resultDir', f'{result_dir}',
              '--viewPort', 'maximize',
              '--preURL', 'about:blank',
              # '--chrome.noDefaultOptions', #TODO
              '--preURLDelay', '1000',
              f'--{browser.browsertime_binary}.binaryPath', browser.binary()]
      for arg in browser.get_args():
        assert arg.startswith('--')
        args.extend(['--chrome.args', arg[2:]])
      args.append(url)
      logging.debug(args)
      subprocess.check_call(args)
      with open(os.path.join(result_dir, 'browsertime.json'), 'r') as output:
        data = json.load(output)
        timings = data[0]['statistics']['timings']
        results.append(('fullyLoaded', url, timings['fullyLoaded']['mean']))
        results.append(('largestContentfulPaint', url, timings['largestContentfulPaint']['loadTime']['mean']))
        results.append(('loadEventEnd', url, timings['loadEventEnd']['mean']))
      with open(os.path.join(result_dir, 'browsertime.har'), 'r') as har:
        total_bytes = 0
        data = json.load(har)
        for e in data['log']['entries']:
          total_bytes += e['response']['_transferSize']
        results.append(('totalBytes', url, total_bytes))

    return results
