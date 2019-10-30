param (
	[Parameter(Mandatory=$true)][string]$test,
	[Parameter(Mandatory=$true)][string]$connectivity
)

$browsers = @("Chrome", "Brave", "Firefox", "Opera")

$i = 0
Get-Content $test | ForEach-Object {
	$page = $_
	foreach ($browser in $browsers) {
		$browser = $browsers[$i]
		switch ($browser)
		{
			"Brave" {
				$spbrowser="chrome"
				$binaryFlag="--$spbrowser.binaryPath"
				$binaryPath="$ENV:LOCALAPPDATA\BraveSoftware\Brave-Browser-Beta\Application\brave.exe"
				$driver="--chrome.chromedriverPath=chromedrivers/win/chromedriver.exe"
			}
			"Chrome" {
				$spbrowser="chrome"
				$binaryFlag="--$spbrowser.binaryPath"
				$binaryPath="${Env:Programfiles(x86)}\Google\Chrome Beta\Application\chrome.exe"
				$driver="--chrome.chromedriverPath=chromedrivers/win/chromedriver.exe"
			}
			"Opera" {
				$spbrowser="chrome"
				$binaryFlag="--$spbrowser.binaryPath"
				$binaryPath="$ENV:LOCALAPPDATA\Programs\Opera\64.0.3417.73\opera.exe"
				$driver="--chrome.chromedriverPath=chromedrivers/win/operadriver.exe"
			}
			"Firefox" {
				$spbrowser="firefox"
				$binaryFlag=""
				$binaryPath=""
				$driver=""
			}
		}
		
		Write-Output "Testing $browser with $page"

		browsertime -b $spbrowser $binaryFlag $binaryPath $driver `
			--iterations 3 `
			--pageCompleteCheckInactivity `
			--resultDir browsertime/$BROWSER/$connectivity/$i `
			--viewPort maximize `
			--connectivity.alias $connectivity `
			$page
	}
	$i += 1
}

