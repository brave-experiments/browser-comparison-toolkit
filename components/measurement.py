from components.browser import Browser
from typing import List, Dict, Optional, Tuple, Type

class MeasurementState:
  urls: List[str]
  unsafe_use_profiles = False
  low_delays_for_testing = False

class Measurement:
  state: MeasurementState

  def __init__(self, state: MeasurementState):
    self.state = state

  def Run(self, iteration: int, browser_class: Type[Browser]) -> List[Tuple[str, Optional[str], float]]:
    raise RuntimeError('Not implemented')
