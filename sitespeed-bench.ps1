param (
    [Parameter(Mandatory=$true)][string]$browser,
	[Parameter(Mandatory=$true)][string]$test,
	[Parameter(Mandatory=$true)][string]$url
)

switch ($browser)
{
	"Brave" {
		$spbrowser="chrome"
		$binaryPath="$ENV:LOCALAPPDATA\BraveSoftware\Brave-Browser-Beta\Application\"
		$driver="--chrome.chromeDriverPath=chromedrivers/win32/chromedriver.exe"
	}
	"Chrome" {
		$spbrowser="chrome"
		$binaryPath="chrome.exe"
		$driver="--chrome.chromeDriverPath=chromedrivers/win32/chromedriver.exe"
	}
}

browsertime -b $spbrowser --$spdriver.binaryPath $binaryPath $driver`
	-n 3 `
	--pageCompleteCheckInactivity `
	--resultDir browsertime/$BROWSER/4g/$i `
	--viewPort maximize `
	--connectivity.alias unthrottled `
	$url
				

