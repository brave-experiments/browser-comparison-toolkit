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

class BenchmarkMeasurement(Measurement):
  def Run(self, iteration: int, browser_class: Type[Browser]) -> List[Tuple[str, Optional[str], float]]:
    urls = self.state.urls
    results: List[Tuple[str, Optional[str], float]] = []

    for i in range(len(urls)):
      browser = browser_class()
      name = urls[i]
      script = os.path.join('benchmark_scripts', name)
      assert os.path.exists(script)
      browser.prepare_profile(self.state.unsafe_use_profiles)
      result_dir = f'browsertime/{browser.name()}/{i}_{name}/{iteration}/'
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
              '--timeouts.script', str(30 * 60 * 1000),
              '--preURLDelay', str(preURLDelay),
              f'--{browser.browsertime_binary}.binaryPath', browser.binary()]
      for arg in browser.get_args():
        assert arg.startswith('--')
        args.extend(['--chrome.args', arg[2:]])
      args.append(script)
      logging.debug(args)
      subprocess.check_call(args)
      with open(os.path.join(result_dir, 'browsertime.json'), 'r') as output:
        data = json.load(output)
        js_metrics = data[0]['extras'][0]
        for metric, value in js_metrics.items():
          results.append((metric, None, value))
      # with open(os.path.join(result_dir, 'browsertime.har'), 'r') as har:
      #   total_bytes = 0
      #   data = json.load(har)
      #   for e in data['log']['entries']:
      #     total_bytes += e['response']['_transferSize']
      #   results.append(('totalBytes', domain, total_bytes))

    return results
