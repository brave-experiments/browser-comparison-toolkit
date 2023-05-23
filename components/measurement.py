from components.browser import Browser
from typing import List, Tuple

class Measurement:
  def Run(self, browser: Browser) -> List[Tuple[str, float]]:
    raise RuntimeError('Not implemented')
