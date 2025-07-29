<#
    The example code below demonstrates how to 
    1. Read performance statistics from Royal Server

    2025-07-29  Creation
#>
Import-Module Royalserver.Powershell.dll

###############################################################################
# variables - adapt to your needs

$royalServerHost = "127.0.0.1"
$port = 54899
$adminUsername = "user"
$adminPassword = "pwd"
$pwd = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force

###############################################################################
# 1. Read performance statistics from Royal Server
###############################################################################
$cred = New-Object System.Management.Automation.PSCredential ($adminUsername, $pwd)
$config = New-RoyalServerConfig -Host $royalServerHost -Port $port -Credential $cred -UseSSL $true
$stats = get-royalserverstatistics -RoyalServerConfig $config

Write-Host "Royal Server Status: $($stats.Status)"
Write-Host "Royal Server Performance"
$stats.performance | Format-Table
Write-Host "Uptime $($stats.Performance.Uptime.Value)"

Write-Host "Open Secure Gateway Connections"
$connections = get-securegatewayconnections -RoyalServerConfig $config
$connections | Format-Table
