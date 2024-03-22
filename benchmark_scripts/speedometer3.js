const URL = 'https://www.browserbench.org/Speedometer3.0/'
async function waitForResults(commands) {
  while (true) {
    await commands.wait.byTime(3000)
    value = await commands.js.run(
      "return window.document.getElementById('result-number').innerHTML")
    if (value && value != '')
      return value
  }
}

async function start(commands) {
  await commands.js.run("window.document.getElementsByClassName('start-tests-button')[0].click()");
}


async function perfTest(context, commands) {
  await commands.navigate(`${URL}?iterationCount=1`);
  await start(commands);
  await waitForResults(commands);

  await commands.measure.start(`${URL}?iterationCount=100`);
  await start(commands);
  const value = await waitForResults(commands);

  confidence_number = await commands.js.run(
    "return window.document.getElementById('confidence-number').innerHTML.substr(2)")
  console.log('got result', value, 'std=', confidence_number)
  commands.measure.addObject(
    { 'speedometer3_score': parseFloat(value),
      'speedometer3_confidence': parseFloat(confidence_number)
    });

  await commands.screenshot.take('result')
};

module.exports = {
  test: perfTest
};
