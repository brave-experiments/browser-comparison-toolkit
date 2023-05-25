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

from typing import List, Optional, Tuple, Type
from urllib.parse import urlparse

from components.browser import Browser
from components.measurement import Measurement
from components.utils import is_win

class BrowsertimeMeasurement(Measurement):
  def Run(self, iteration: int, browser_class: Type[Browser]) -> List[Tuple[str, str, float]]:
    urls = self.state.urls
    results:List[Tuple[str, str, float]] = []

    for i in range(len(urls)):
      browser = browser_class()
      browser.prepare_profile(self.state.unsafe_use_profiles)
      domain = urlparse(urls[i]).netloc
      result_dir = f'browsertime/{browser.name()}/{i}_{domain}/{iteration}/'
      preURLDelay = 1000 if self.state.low_delays_for_testing else 10000
      npm_binary = 'npm.cmd' if is_win() else 'npm'
      args = [npm_binary, 'exec', 'browsertime', '--',
              '-b', browser.browsertime_binary,
              '-n', '1',
              '--useSameDir',
              '--resultDir', f'{result_dir}',
              '--viewPort', 'maximize',
              '--preURL', 'about:blank',
              # '--chrome.noDefaultOptions', #TODO
              '--preURLDelay', str(preURLDelay),
              f'--{browser.browsertime_binary}.binaryPath', browser.binary()]
      for arg in browser.get_args():
        assert arg.startswith('--')
        args.extend(['--chrome.args', arg[2:]])
      args.append(urls[i])
      logging.debug(args)
      subprocess.check_call(args)
      with open(os.path.join(result_dir, 'browsertime.json'), 'r') as output:
        data = json.load(output)
        timings = data[0]['statistics']['timings']
        results.append(('fullyLoaded', domain, timings['fullyLoaded']['mean']))
        results.append(('largestContentfulPaint', domain, timings['largestContentfulPaint']['loadTime']['mean']))
        results.append(('loadEventEnd', domain, timings['loadEventEnd']['mean']))
      with open(os.path.join(result_dir, 'browsertime.har'), 'r') as har:
        total_bytes = 0
        data = json.load(har)
        for e in data['log']['entries']:
          total_bytes += e['response']['_transferSize']
        results.append(('totalBytes', domain, total_bytes))

    return results
