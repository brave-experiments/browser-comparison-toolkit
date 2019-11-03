
## Testing scenarios

We are interested in real-world browser performance, so we want to test the browsers against real pages.

This tool currently assumes very simple usage scenarios: opening individual pages with no interaction on them.

Current test scenarios are defined in the `scenarios/` directory:

- `fullset.txt` includes all URLs of interest
- `single-*.txt` is for opening just a single, randomly selected URL in a browsing sesssion
- `five-*.txt` is for opening 5 randomly selected pages concurrently, mostly used for measuring memory use with 5 pages open at a time
- `ten-*.txt` and `twenty-*.txt` files define ten and twenty pages respectively to be opened at a time, also primarily for memory measurements.


## Memory measurements

There are many correct ways of evaluating a programs memory use, especially for multi-process architectures. Modern browsers have their own internal tooling for detailed memory profiling which tells _how_ the memory is used. However, for a consistent comparison across different browsers with different architectures we rely on the platform's tooling to extract the numbers reported by the _Activity Monitor_ (MacOS) or _Task Manager_ (Windows).

This repository contains two scripts for memory measurements:

- `memory-bench.sh`: a Bash script for MacOS
- `memory-bench.ps1`: a PowerShell for Windows 10

Each script accepts the name of the browser to test and the scenarios to test it against as input parameters, and runs through each scenario (a single file) by opening every URL in the file with 5 seconds in between subsequent pages, finally waiting 30 seconds until doing the measurement, and gracefully closing the browser.

For the test, the browsers were manually configured to:

- start with the default landing page every time and not restore previous browsing session
- not ask for user confirmation when closing a window with multiple tabs open

To use the scripts for example to measure memory using the 5-page scenarios, on MacOS:

```bash
./memory-bench.sh Brave five
```

And on Windows:

```PowerShell
.\memory-bench.ps1 Brave five
```

Importantly, the scripts on both platforms take care of gracefully shutting the browsers down, otherwise the browser assumes on next start that it had crashed and shows additional notifications, suggesting to restore session, etc. as well as sometimes corrupting user profile and subsequently failing to start altogether.


## Performance measurements

To measure browser performance and bandwidth across all the different browsers, we we used a third-party tool, [Browsertime](https://www.sitespeed.io/documentation/browsertime/) that interfaces with every browser’s built-in automation.

A few gotchas with Browsertime:

- It works with Safari, but it does not appear to clear caches, making it not directly comparable to others
- The `firstPaint` and `rumSpeedIndex` metrics currently report the same value, which indicates an issue with at least one of them
- It produces HAR files for other browsers, but HARs from Firefox do not include `_transferSize` field, so the actual request transfer size needs to be computed from request body and header sizes
- Documentation says Browsertime does not work on Windows - in fact it does, but requires explicitly specifying binary path for each browser tested
- Browsertime by default waits until the `onLoad` event, but can be configured to wait until network activity stops using the `--pageCompleteCheckInactivity` flag. Documentation states that it waits for 2 seconds, but code uses 5 seconds, in line with Lighthouse defaults.

We used Browsertime to load every page in our test set 3 times, restarting the browser with a new user profile between tests and running each test until there was no network activity for at least 5 seconds. The “fully loaded” time is computed by Browsertime as the time between starting the first network request in loading the page, until the very last request. Browsertime does not automatically compute the total transfer size, but we computed it from the produced HAR files as the sum of browser’s reported transfer size of each request during a page load.

To use the script with all the pages in our test scenarios on MacOS:

```bash
./sitespeed-bench.sh ./scenarios/fullset.txt 4g
```

And on Windows:

```PowerShell
.\sitespeed-bench.ps1 .\scenarios\fullset.txt 4g
```

Network connectivity here is specified only to be included in the generated output, but does not in fact change any network settings. In our tests we throttle network connectivity using MacOS "Network Link Conditioner" and relied on the WiFi access point functionality to limit network speed for Windows due to lack of a built-in tool.

Finally the `collect.sh` script iterates through all Browsertime's trace files, extracting the metrics of interest and producing a single CSV file ready to be imported in a data processing tool, e.g.:

```
./collect.sh browsertime/ 4g 4g-mac.csv
```
