async function perfTest(context, commands) {
  await commands.measure.start('https://browserbench.org/Speedometer2.0/?iterationCount=10');
  await commands.js.run('startTest()');

  while (true) {
    await commands.wait.byTime(3000)
    value = await commands.js.run("return window.document.getElementById('result-number').innerHTML")
    if (value && value != '' ) {
      console.log('got result', value)
      commands.measure.addObject({ 'speedometer2_score': parseFloat(value)});
      break;
    }
  }
  // try {
  //   commands.screenshot.take('result')
  // } catch (e) {
  //   console.error(e)
  // }
};

module.exports = {
  test: perfTest
};
