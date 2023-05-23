import os
import shutil
import subprocess
from tempfile import TemporaryDirectory
import time
from typing import Dict, List, Optional, Tuple
import psutil
import logging
import platform


class Browser:
  binary_name: str
  use_user_data_dir: bool = True
  temp_user_data_dir: Optional[TemporaryDirectory] = None

  profile_dir: Optional[str] = None
  args: List[str] = []

  process: Optional[subprocess.Popen] = None

  @classmethod
  def name(cls) -> str:
    return cls.__name__

  def binary(self) -> str:
    return f'/Applications/{self.binary_name}.app/Contents/MacOS/{self.binary_name}'

  def _get_start_cmd(self, use_source_profile = False) -> List[str]:
    args = [self.binary()]
    if self.use_user_data_dir:
      if use_source_profile:
        args.append(f'--user-data-dir={self._get_source_profile()}')
      else:
        args.append(f'--user-data-dir={self._get_target_profile()}')

    args.extend(self.args)
    return args

  def get_all_processes(self) -> List[psutil.Process]:
    assert self.process is not None
    main_process = psutil.Process(self.process.pid)
    processes = [main_process]
    children = main_process.children(recursive=True)
    for child in children:
      processes.append(child)
    return processes


  def _get_source_profile(self) -> str:
    dir = os.path.join(os.curdir, 'browser_profiles', platform.system(), self.name())
    return dir

  def _get_target_profile(self) -> str:
    if self.use_user_data_dir:
      if self.temp_user_data_dir is None:
        self.temp_user_data_dir = TemporaryDirectory(prefix = self.name() + '-user-data-')
      return self.temp_user_data_dir.name
    assert self.profile_dir
    return self.profile_dir

  def prepare_profile(self, unsafe = False):
      target_profile = self._get_target_profile()
      if os.path.exists(target_profile):
        if not self.use_user_data_dir and unsafe == False:
          accept = input(f'Have you backup your profile {target_profile}? Type YES to delete it and continue.')
          if accept != 'YES':
            raise RuntimeError(f'Aborted by user')
        shutil.rmtree(target_profile)
      if not os.path.exists(self._get_source_profile()):
        raise RuntimeError(f'Can\'t find source profile')
      shutil.copytree(self._get_source_profile(), self._get_target_profile())


  def start(self, use_source_profile=False):
    assert self.process is None
    self.process = subprocess.Popen(self._get_start_cmd(use_source_profile), stdout=subprocess.PIPE, stderr=subprocess.PIPE)

  def terminate(self):
    assert self.process is not None
    self.process.terminate()
    time.sleep(1)
    self.process.kill()

  def open_url(self, url: str):
    assert self.process is not None
    rv = subprocess.call(self._get_start_cmd() + [url], stdout=subprocess.PIPE)
    if self.name() != 'Opera':
      assert rv == 0

class Brave(Browser):
  binary_name = 'Brave Browser'

class Chrome(Browser):
  binary_name = 'Google Chrome'

class ChromeUBO(Browser):
  binary_name = 'Google Chrome'

class Opera(Browser):
  binary_name = 'Opera'

class Edge(Browser):
  binary_name = 'Microsoft Edge'

class Safari(Browser):
  binary_name = 'Safari'
  use_user_data_dir = False
  profile_dir = '~/Library/Safari'

class Firefox(Browser):
  binary_name = 'Firefox'
  use_user_data_dir = False
  profile_dir = '~/Library/Application Support/Firefox/'


BROWSER_LIST = [Brave, Chrome, ChromeUBO, Opera, Edge] #, Safari, Firefox]

def get_browsers_classes_by_name(name: str):
  if name == 'all':
    return BROWSER_LIST
  for b in BROWSER_LIST:
    if b.name() == name:
      return [b]
  raise RuntimeError(f'No browser with name {name} found')
