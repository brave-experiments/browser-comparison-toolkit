param (
    [Parameter(Mandatory=$true)][string]$browser,
	[Parameter(Mandatory=$true)][string]$test,
	[Parameter(Mandatory=$true)][string]$url
)

switch ($browser)
{
	"Brave" {
		$spbrowser="chrome"
		$binaryFlag="--$spbrowser.binaryPath"
		$binaryPath="$ENV:LOCALAPPDATA\BraveSoftware\Brave-Browser-Beta\Application\brave.exe"
		$driver="--chrome.chromeDriverPath=chromedrivers/win/chromedriver.exe"
	}
	"Chrome" {
		$spbrowser="chrome"
		$binaryFlag="--$spbrowser.binaryPath"
		$binaryPath="${Env:Programfiles(x86)}\Google\Chrome Beta\Application\chrome.exe"
		$driver="--chrome.chromeDriverPath=chromedrivers/win/chromedriver.exe"
	}
	"Opera" {
		$spbrowser="chrome"
		$binaryFlag="--$spbrowser.binaryPath"
		$binaryPath="$ENV:LOCALAPPDATA\Programs\Opera\launcher.exe"
		$driver="--chrome.chromeDriverPath=chromedrivers/win/operadriver.exe"
	}
	"Firefox" {
		$spbrowser="firefox"
		$binaryFlag=""
		$binaryPath=""
		$driver=""
	}
}

browsertime -b $spbrowser $binaryFlag $binaryPath $driver `
	--iterations 3 `
	--pageCompleteCheckInactivity `
	--resultDir browsertime/$BROWSER/4g/$i `
	--viewPort maximize `
	--connectivity.alias unthrottled `
	$url


