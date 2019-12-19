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
    $workingdir = "$ENV:LOCALAPPDATA$braveapplication"
}

$userdatadir = "$pwd\mem-test\"
$scenariosdir = "$pwd\scenarios\"

Write-Output "Running scenarios $test*.txt from $scenariosdir"

$result = @{scenarios = @()}

Get-ChildItem $scenariosdir -Filter $test*.txt | Foreach-Object {
    $fullname = $_.FullName
    $test = $_.Name

    $testresult = @{test = $test; runs = @()}
    
    for ($i=1; $i -le $repeats; $i++) {
        # Start-Process -FilePath $browser -WorkingDirectory $workingdir -ArgumentList --user-data-dir=$userdatadir, --no-first-run
        # Start-Sleep -Seconds 5
    
        # Get-Content $fullname | ForEach-Object {
        #     $page = $_
        #     Write-Output "Opening page $page"
        #     Start-Process -FilePath $browser -WorkingDirectory $workingdir -ArgumentList --user-data-dir=$userdatadir, --no-first-run, $page
        #     Start-Sleep -Seconds 5
        # }
    

        # Start-Sleep -Seconds $wait

        # # $m = ps $browser | measure PM -Sum

        # $m = Get-WmiObject -class Win32_PerfFormattedData_PerfProc_Process -filter "Name LIKE '$($browser)%'" |
        #     Select-Object -expand workingSetPrivate |
        #     Measure-Object -sum
        
        # ("$browser $test $i {0:N2}MB " -f ($m.sum / 1mb))

        # $testresult.runs += $m.sum
        $testresult.runs += 3000

        # $process = Get-Process -Name $browser
        # while ($process -ne $null) {
        #     Write-Output "Browser Process Running, attempting to close main window: $process"
        #     $process | Stop-Process -Force
        #     Start-Sleep 5
        #     $process = Get-Process -Name $browser -ErrorAction SilentlyContinue
        # }
        # Remove-Item -Recurse -Force $userdatadir

    }

    $result.scenarios += $testresult
}

$result | ConvertTo-Json -Depth 4 -Compress | 
    Out-File -FilePath memory-results.json -Encoding UTF8

Get-Content -Path "$pwd\memory-results.json"
