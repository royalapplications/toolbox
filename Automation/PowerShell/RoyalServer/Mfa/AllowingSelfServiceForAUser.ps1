<#
    The example code below demonstrates how to set the Self-Service attribute 
    for a user to the opposite of he current state

    22-07-2025  Creation
#>
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $ScriptDir\RoyalServer.PowerShell.Mfa.psm1
$ErrorActionPreference = 'Stop'

###############################################################################
# variables - adapt to your needs
$adminUsername = "user"
$adminPassword = ConvertTo-SecureString "pwd" -AsPlainText -Force
$serverIPAddress = "127.0.0.1"
$userToChange = "user"


$adminCredential = New-Object System.Management.Automation.PSCredential ("$adminUsername", $adminPassword)
$config = New-RoyalServerConfig -Host "$serverIPAddress" -UseSSL $true -Port 54899 -Credential $adminCredential

$userName = "$env:COMPUTERNAME\$userToChange"
$user = Get-MfaUser -Config $config | Where-Object -Property UserName -EQ $userName

$provider = Get-ProviderString -Provider $user.Provider
$requireDocStore = -Not $user.RequireDocStore

Set-MfaUser -Config $config -MfaId $user.MfaId -Username $user.Username -Sid $user.PrincipalSid `
    -Comment "update SelfService at $(Get-Date)" -CacheSuccessFor $user.CacheSuccessFor `
    -Provider $provider -RequireDocStore $requireDocStore | Out-Null

Write-Host "RequireDocStore for user $($user.Username) changed to $requireDocStore" 
