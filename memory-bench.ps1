param (
    [Parameter(Mandatory=$true)][string]$browser,
    [Parameter(Mandatory=$true)][string]$test
)

Write-Output "Measuring $browser for scenario $test"

$repeats = 3
$wait = 30
$braveapplication = '\BraveSoftware\Brave-Browser\Application\'
$localinstall = Test-Path -Path $ENV:LOCALAPPDATA$braveapplication
if ($localinstall) {
    $workingdir = "-WorkingDirectory $localinstall"
}

$userdatadir = '.\mem-test\'

Get-ChildItem ".\scenarios\" -Filter $test*.txt | Foreach-Object {
    $fullname = $_.FullName
    $test = $_.Name
    
    for ($i=1; $i -le $repeats; $i++) {
        Start-Process -FilePath $browser $workingdir -ArgumentList --user-data-dir=$userdatadir, --no-first-run
        Start-Sleep -Seconds 5
    
        Get-Content $fullname | ForEach-Object {
            $page = $_
            Write-Output "Opening page $page"
            Start-Process -FilePath $browser $workingdir -ArgumentList --user-data-dir=$userdatadir, --no-first-run, $page
            Start-Sleep -Seconds 5
        }
    

        Start-Sleep -Seconds $wait

        # $m = ps $browser | measure PM -Sum

        $m = Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process -filter "Name LIKE '$($browser)%'" |
            Select -expand workingSetPrivate |
            Measure-Object -sum
        
        ("$browser $test $i {0:N2}MB " -f ($m.sum / 1mb))

        $process = Get-Process -Name $browser
        while ($process -ne $null) {
            echo "Browser Process Running, attempting to close main window: $process"
            $process | Stop-Process -Force
            Start-Sleep 5
            $process = Get-Process -Name $browser -ErrorAction SilentlyContinue
        }
        rm $userdatadir

    }
}
