async function perfTest(context, commands) {
  await commands.measure.start(
    'https://browserbench.org/JetStream2.0/');
  await commands.js.run('JetStream.start()');

  while (true) {
    await commands.wait.byTime(3000)
    raw = await commands.js.run(
      "return document.getElementById('result-summary')?.childNodes[0]?.textContent")

    if (raw && raw != '') {
      console.log('got result', raw)
      commands.measure.addObject({ 'jetstream2_score': parseFloat(raw) });
      break;
    }
  }
  await commands.screenshot.take('result')
};

module.exports = {
  test: perfTest
};
