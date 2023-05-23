import platform
import re
import logging
import subprocess
import math
import time
import psutil

from components.browser import Browser
from components.measurement import Measurement
from typing import Dict, List, Optional, Tuple

def _get_private_memory_usage_mac(pid: int) -> float:
  output = subprocess.run(
        f'vmmap --summary {pid}' + '| grep "Physical footprint:"',
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE,
        text=True,
        shell=True).stdout
  m = re.search('Physical footprint: *([\\d|.]*)(.)', output)
  assert m is not None

  val = float(m.group(1))

  assert len(m.group(2)) == 1
  scale =  m.group(2)[0]

  ex = ['K', 'M', 'G'].index(scale) + 1
  mem = val * math.pow(1024,ex)
  logging.debug('%d %f %s %d %f', pid, val, scale, ex, mem)
  return mem

def _get_private_memory_usage_win(pid: int) -> float:
  output = subprocess.check_output(['powershell.exe', '-Command', f'WmiObject -class Win32_PerfFormattedData_PerfProc_Process -filter "IDProcess like {pid}" | Select-Object -expand workingSetPrivate'], text=True)
  pmf = float(output.rstrip())
  assert(pmf > 0)
  return pmf

def _get_private_memory_usage(pid: int) -> float:
  if platform.system() == 'Darwin':
    return _get_private_memory_usage_mac(pid)
  if platform.system() == 'Windows':
    return _get_private_memory_usage_win(pid)
  raise RuntimeError('Platform is not supported')


def _get_browser_private_memory_usage(browser: Browser) -> float:
  total: float = 0
  for p in browser.get_all_processes():
    logging.debug(p)
    if p.is_running() and p.status() != psutil.STATUS_ZOMBIE:
      total +=_get_private_memory_usage(p.pid)
  return total

class MemoryMeasurement:
  start_delay = 5
  open_url_delay = 5
  measure_delay = 60
  terminate_delay = 10

  def __init__(self, short_delay_for_testing = False) -> None:
    if short_delay_for_testing:
      self.start_delay = 1
      self.open_url_delay = 1
      self.measure_delay = 5
      self.terminate_delay = 5


  def Run(self, urls: List[str], browser: Browser, unsafe: bool) -> Dict[str, float]:
    try:
      browser.prepare_profile(unsafe)
      browser.start()
      time.sleep(self.start_delay)
      for url in urls:
        browser.open_url(url)
        time.sleep(self.open_url_delay)
      time.sleep(self.measure_delay)

      private_memory = _get_browser_private_memory_usage(browser)
      assert private_memory > 0
    finally:
      browser.terminate()
    time.sleep(self.terminate_delay)
    return {'TotalPrivateMemory': private_memory}
