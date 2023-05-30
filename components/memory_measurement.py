# Copyright (c) 2023 The Brave Authors. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at https://mozilla.org/MPL/2.0/.

import platform
import re
import logging
import subprocess
import math
import time
import psutil

from typing import List, Optional, Tuple, Type

from components.browser import Browser
from components.measurement import Measurement, MeasurementState


def _get_private_memory_usage_mac(pid: int) -> Optional[float]:
  output = subprocess.run(
      f'vmmap --summary {pid}' + '| grep "Physical footprint:"',
      stderr=subprocess.PIPE,
      stdout=subprocess.PIPE,
      text=True,
      check=False,
      shell=True).stdout
  m = re.search('Physical footprint: *([\\d|.]*)(.)', output)
  if m is None:
    return None

  val = float(m.group(1))

  assert len(m.group(2)) == 1
  scale = m.group(2)[0]

  ex = ['K', 'M', 'G'].index(scale) + 1
  mem = val * math.pow(1024, ex)
  logging.debug('%d %f %s %d %f', pid, val, scale, ex, mem)
  return mem


def _get_private_memory_usage_win(pid: int) -> Optional[float]:
  args = [
      'powershell.exe', '-Command',
      ('WmiObject -class Win32_PerfFormattedData_PerfProc_Process' +
       f' -filter "IDProcess like {pid}" | ' +
       'Select-Object -expand workingSetPrivate')
  ]
  result = subprocess.run(args, stdout = subprocess.PIPE, text=True)
  if result.returncode != 0:
    return None
  pmf = float(result.stdout.rstrip())
  assert (pmf > 0)
  return pmf


def _get_private_memory_usage(pid: int) -> Optional[float]:
  if platform.system() == 'Darwin':
    return _get_private_memory_usage_mac(pid)
  if platform.system() == 'Windows':
    return _get_private_memory_usage_win(pid)
  raise RuntimeError('Platform is not supported')


def _get_browser_private_memory_usage(browser: Browser) -> float:
  total_private: float = 0
  for p in browser.get_all_processes():
    logging.debug(p)
    if p.is_running() and p.status() != psutil.STATUS_ZOMBIE:
      private = _get_private_memory_usage(p.pid)
      assert private is not None
      total_private += private
  return total_private


class MemoryMeasurement(Measurement):
  start_delay = 5
  open_url_delay = 5
  measure_delay = 60
  terminate_delay = 10

  def __init__(self, state: MeasurementState) -> None:
    super().__init__(state)
    if state.low_delays_for_testing:
      self.start_delay = 1
      self.open_url_delay = 1
      self.measure_delay = 5
      self.terminate_delay = 5

  def Run(
      self, _,
      browser_class: Type[Browser]) -> List[Tuple[str, Optional[str], float]]:
    browser = browser_class()
    try:
      browser.prepare_profile(self.state.unsafe_use_profiles)
      browser.start()
      time.sleep(self.start_delay)
      for url in self.state.urls:
        browser.open_url(url)
        time.sleep(self.open_url_delay)
      time.sleep(self.measure_delay)

      private_memory = _get_browser_private_memory_usage(browser)
      assert private_memory > 0
    finally:
      browser.terminate()
    time.sleep(self.terminate_delay)
    return [('TotalPrivateMemory', None, private_memory)]
