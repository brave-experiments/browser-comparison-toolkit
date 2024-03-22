# Copyright (c) 2023 The Brave Authors. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at https://mozilla.org/MPL/2.0/.

import json
import os
import logging
import subprocess

from typing import Dict, List, Optional, Tuple

from components.browser import Browser
from components.utils import is_win

DEFAULT_CHROME_OPTIONS = [
  '--new-window',
  '--no-default-browser-check',
  '--no-first-run',
  '--password-store=basic',
  '--use-mock-keychain',
  '--remote-debugging-port=9222']

def run_browsertime(browser: Browser, cmd: str, result_dir: str,
                    extra_args: List[str]) -> Tuple[Dict, Optional[Dict]]:
  npm_binary = 'npm.cmd' if is_win() else 'npm'
  args = ([npm_binary, 'exec', 'browsertime', '--'] +
          ['-b', browser.browsertime_binary] + ['-n', '1'] +
          ['--useSameDir', '--resultDir', f'{result_dir}'] +
          ['--viewPort', 'maximize'] + ['--preURL', 'about:blank'] +
          [f'--{browser.browsertime_binary}.binaryPath',
           browser.binary()])
  args.extend(extra_args)
  args.append('--chrome.noDefaultOptions')
  for arg in browser.get_args() + DEFAULT_CHROME_OPTIONS:
    assert arg.startswith('--')
    args.extend(['--chrome.args', arg[2:]])

  # for arg in DEFAULT_CHROME_OPTIONS:
  #   args.extend(['--chrome.args', arg[2:]])
  # TODO: support --chrome.noDefaultOptions?
  # args.extend(['--chrome.args', 'remote-debugging-port=9222'])
  # args.extend(['--chrome.args', 'test-type=webdriver'])

  args.append(cmd)
  logging.debug(args)
  subprocess.check_call(args)
  output_file = os.path.join(result_dir, 'browsertime.json')
  with open(output_file, 'r', encoding='utf-8') as output:
    output_json = json.load(output)[0]

  har_json = None
  try:
    har_file = os.path.join(result_dir, 'browsertime.har')
    with open(har_file, 'r', encoding='utf-8') as har:
      har_json = json.load(har)
  except FileNotFoundError:
    pass
  return output_json, har_json


def get_total_transfer_bytes(har_json: Dict) -> int:
  total_bytes = 0
  for e in har_json['log']['entries']:
    total_bytes += e['response']['_transferSize']
  return total_bytes
