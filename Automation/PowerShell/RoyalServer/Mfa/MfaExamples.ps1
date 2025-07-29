<#
    The example code below demonstrates how to use the functions in RoyalServer.PowerShell.Mfa.psm1 
    It 
    - Example 1: List all users configured for MFA
    - Example 2: List all users configured for TOTP MFA
    - Example 3: List all users configured for DUO MFA
    - Example 4: List all users configured for YubiKey MFA
    - Example 5: Add a new TOTP user
    - Example 6: Add a new DUO user
    - Example 7: Add a new Yubikey user
    - Example 8: Remove one MFA user entry
    - Example 9: Change properties of an existing TOTP MFA config

    2023-05-10  Creation
    2025-07-21  Adaptation, added methods for specific MFA provider
#>
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path
Import-Module $ScriptDir\RoyalServer.PowerShell.Mfa.psm1
$ErrorActionPreference = 'Stop'

###############################################################################
# variables - adapt to your needs
$adminUsername = "user"
$adminPassword = ConvertTo-SecureString "pwd" -AsPlainText -Force
$serverIPAddress = "127.0.0.1"


$adminCredential = New-Object System.Management.Automation.PSCredential ("$adminUsername", $adminPassword)
$config = New-RoyalServerConfig -Host "$serverIPAddress" -UseSSL $true -Port 54899 -Credential $adminCredential

###############################################################################
# Example 1
# List all configured users for MFA
###############################################################################
Write-Host "Listing all users configured for MFA:"
Get-MfaUser -Config $config | Format-Table

###############################################################################
# Example 2
# List all users configured for TOTP MFA
###############################################################################
Write-Host "Users configured for TOTP"
Get-TotpUser -Config $config | Format-Table

###############################################################################
# Example 3
# List all users configured for DUO MFA
###############################################################################
Write-Host "Users configured for DUO"
Get-DuoUser -Config $config | Format-Table

###############################################################################
# Example 4
# List all users configured for Yubikey MFA
###############################################################################
Write-Host "Users configured for Yubikey"
Get-YubikeyUser -Config $config | Format-Table

###############################################################################
# Example 5
# Add a new TOTP user
###############################################################################
$tun = Read-Host "Please enter the Username for the TOTP MFA configuration"
$totpUsername = "$env:COMPUTERNAME\$tun"
$Sid = Get-AccountSid $totpUsername
$comment = "Scripted TOTP User"
$CacheSuccessFor = "01:30:00" #1 hour, 30 mins
$requireDocStore = $true
$requireSecureGateway = $true
$selfServiceAllowed = $true

Add-TotpUser -Config $config -Sid $sid -Username $totpUsername -Comment $comment -CacheSuccessFor $CacheSuccessFor `
    -RequireDocStore $requireDocStore -RequireSecureGateway $requireSecureGateway -SelfServiceAllowed $selfServiceAllowed


###############################################################################
# Example 6
# Add a new DUO user
###############################################################################
$dun = Read-Host "Please enter the Username for the DUO MFA configuration"
$duoUsername = "$env:COMPUTERNAME\$dun"
$duoSid = Get-AccountSid $duoUsername
$duoUserId = Read-Host "Please enter the DUO User Id: "
Add-DuoUser -Config $config -Sid $duoSid -Username $duoUsername -Comment "Scripted DUO User" -CacheSuccessFor $CacheSuccessFor `
    -RequireDocStore $requireDocStore -RequireSecureGateway $requireSecureGateway -DuoUserId $duoUserId

###############################################################################
# Example 7
# Add a new Yubikey user
###############################################################################
$dyn = Read-Host "Please enter the Username for the Yubikey MFA configuration"
$yubikeyUsername = "$env:COMPUTERNAME\$dyn"
$yubikeySid = Get-AccountSid $yubikeyUsername
$yubikeyId = Read-Host "Please enter the Yubikey Id: "
Add-YubikeyUser -Config $config -Sid $yubikeySid -Username $yubikeyUsername -Comment "Scripted Yubikey User" `
    -RequireDocStore $requireDocStore -RequireSecureGateway $requireSecureGateway `
    -YubikeyId $yubikeyId

###############################################################################
# Example 8
# Remove one MFA user entry
# ATTENTION: for demonstration purposes this script removes the 1st entry
###############################################################################
$response = Read-Host "Are you sure you want to remove the first Mfa Configuration? (Y/N)"
if ($response -match '^[Yy]$') {
    $users = @(Get-MfaUser -Config $config)
    $rid = $users[0].MfaID
    $run = $users[0].UserName
    $rsid = $users[0].PrincipalSID
    Remove-MfaUser -Config $config -MfaId $rid -Username $run -Sid $rsid
    Write-Host "MFA configuration $run removed"
        
} else {
    Write-Host "Removing of MFA configuration cancelled."
}

###############################################################################
# Example 9
# Changing a property of an MFA configuration
# Remark: This example looks for the first occurrence of a Yubikey Config
###############################################################################
$yubikeyProvider = [RoyalCommon.Server.RoyalServer.MfaProvider]::Yubikey #TOTP=1, Yubikey=2, Duo=3

$users = @(Get-MfaUser -Config $config) 
foreach($c in $users)
{
    if($c.Provider -eq 2) #TOTP=1, Yubikey=2, Duo=3
    {
        $rid = $c.MfaID
        $run = $c.UserName
        $rsid = $c.PrincipalSID

        Set-MfaUser -Config $config -MfaId $rid -Username $run -Sid $rsid -Comment "new comment" -CacheSuccessFor "00:47:00" `
            -Provider $yubikeyProvider -RequireDocStore $false -RequireSecureGateway $false -YubikeyId 123456789123
        
        Write-Host "Editing MfaId $rid and user $run"
        break       
    }
}

