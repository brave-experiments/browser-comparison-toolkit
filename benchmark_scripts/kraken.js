async function perfTest(context, commands) {
  await commands.measure.start('https://mozilla.github.io/krakenbenchmark.mozilla.org/index.html');
  await commands.click.bySelectorAndWait('a');

  while (true) {
    await commands.wait.byTime(3000)
    raw = await commands.js.run("return window.document.getElementById('console')?.textContent")

    if (raw && raw != '' ) {
      // Example: "Total:   1499.9ms +/- 18.8%".
      m = raw.match(/Total:\s*([\d|.]*)ms\s\+\/-\s([\d|.]*)%/)
      if (!m) {
        console.error(raw)
      }
      console.log('got total', m[1], m[2])
      commands.measure.addObject({ 'kraken_ms': parseFloat(m[1])});
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
