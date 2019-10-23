param (
    [Parameter(Mandatory=$true)][string]$browser,
    [Parameter(Mandatory=$true)][string]$test
)

Write-Output "Measuring $browser for scenario $test"

$repeats = 3
$wait = 30
$braveapplication = '\BraveSoftware\Brave-Browser-Beta\Application\'

for ($i=1; $i -le $repeats; $i++) {
    Start-Process -FilePath $browser -WorkingDirectory $ENV:LOCALAPPDATA$braveapplication
    Start-Sleep -Seconds $wait

    Get-ChildItem ".\scenarios\" -Filter $test*.log | 
    Foreach-Object {
        $fullname = $_.FullName
        $test = $_.Name
        Get-Content $fullname | ForEach-Object {
            $page = $_
            Write-Output "Opening page $page"
            Start-Process -FilePath $browser -WorkingDirectory $ENV:LOCALAPPDATA$braveapplication -ArgumentList $page
            Start-Sleep -Seconds 5
        }
    

        Start-Sleep -Seconds $wait

        $m = ps $browser | measure PM -Sum

        ("$browser $test $i {0:N2}MB " -f ($m.sum / 1mb))

        Get-Process -Name $browser | Foreach-Object { $_.CloseMainWindow() | Out-Null } | Stop-Process
        Start-Sleep -Seconds 5
    }
}
