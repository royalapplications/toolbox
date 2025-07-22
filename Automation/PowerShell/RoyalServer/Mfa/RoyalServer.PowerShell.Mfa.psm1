<#
    This module contains functions to manage MFA user configurations on Royal Server.

    10-05-2023  Creation
    17-07-2025  Enhancements for different MFA Provider
#>
Import-Module Royalserver.PowerShell

New-Variable -name "defaultCacheSuccessFor" -Value "01:00:00" -Scope Global

<#
    .Description
    The Get-TotpUser function lists the MFA users configured for TOTP.
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
#>

function Get-TotpUser() {
    param (
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config
    )

    $response = Invoke-RoyalServerCommand `
        -ModuleID RoyalServerManagement `
        -Command "GetUserMfaConfiguration" `
        -DestinationHost $Config.Host `
        -RoyalServerConfig $Config

    return _FilterByMfaType -Response $response -FilterByMfaProvider 1
}
<#
    .Description
    The Get-DuoUser function lists the MFA users configured for DUO
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
#>
function Get-DuoUser() {
    param (
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config
    )

    $response = Invoke-RoyalServerCommand `
        -ModuleID RoyalServerManagement `
        -Command "GetUserMfaConfiguration" `
        -DestinationHost $Config.Host `
        -RoyalServerConfig $Config

    return _FilterByMfaType -Response $response -FilterByMfaProvider 3
}
<#
    .Description
    The Get-YubikeyUser function lists the MFA users configured for Yubikey
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
#>
function Get-YubikeyUser() {
    param (
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config
    )

    $response = Invoke-RoyalServerCommand `
        -ModuleID RoyalServerManagement `
        -Command "GetUserMfaConfiguration" `
        -DestinationHost $Config.Host `
        -RoyalServerConfig $Config

    return _FilterByMfaType -Response $response -FilterByMfaProvider 2
}

<#
    .Description
    The Add-TotpUser function enrolls a new MFA user for the TOTP provider.
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
    .PARAMETER Sid
    The user's SID. Use Get-AccountSid to get the Sid of a Windows Account.
    .PARAMETER Username
    The user's name.
    .PARAMETER Comment
    Comment for the user entry
    .PARAMETER CacheSuccessFor
    The CacheSuccessFor as a string representation of the DotNet Timespan, e.g. "00:30:00" for 30 mins
    .PARAMETER RequireDocStore
    An optional boolean to require the MFA for Document Store access. Defaults to false.
    .PARAMETER RequireSecureGateway
    An optional boolean to require the MFA for Secure Gateway. Defaults to false.
    .PARAMETER SelfServiceAllowed
    An optional boolean to require a self services workflow for the user. Defaults to false.
    Self-Service can be done here: https://<ROYAL-SERVER-URL>:<PORT>/mfa/totp for the user
#>
function Add-TotpUser {
    param (       
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config,
        [parameter(Mandatory=$true)]
        [string] $Sid,
        [parameter(Mandatory=$true)]
        [string] $Username,
        [string] $Comment,
        [string] $CacheSuccessFor = $defaultCacheSuccessFor,
        [bool] $RequireDocStore = $false,
        [bool] $RequireSecureGateway = $false,
        [bool] $SelfServiceAllowed = $false
    )
    $provider = [RoyalCommon.Server.RoyalServer.MfaProvider]::Generic_TOTP

    _AddMfaUser -Config $Config -Sid $Sid -Provider $provider -Username $Username -Comment $Comment -CacheSuccessFor $CacheSuccessFor `
        -RequireDocStore $requireDocStore -RequireSecureGateway $requireSecureGateway -SelfServiceAllowed $SelfServiceAllowed

}

<#
    .Description
    The Add-YubikeyUser function enrolls a new MFA user for the DUO provider.
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
    .PARAMETER Sid
    The user's SID.
    .PARAMETER Username
    The user's name.
    .PARAMETER Comment
    Comment for the user entry
    .PARAMETER CacheSuccessFor
    The CacheSuccessFor as a string representation of the DotNet Timespan, e.g. "00:30:00" for 30 mins
    .PARAMETER RequireDocStore
    An optional boolean to require the MFA for Document Store access. Defaults to false.
    .PARAMETER RequireSecureGateway
    An optional boolean to require the MFA for Secure Gateway. Defaults to false.
    .PARAMETER YubikeyId
    Id of the Yubikey
#>
function Add-YubiKeyUser {
    param (       
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config,
        [parameter(Mandatory=$true)]
        [string] $Sid,
        [parameter(Mandatory=$true)]
        [string] $Username,
        [string] $Comment,
        [string] $CacheSuccessFor = $defaultCacheSuccessFor,
        [bool] $RequireDocStore = $false,
        [bool] $RequireSecureGateway = $false,
        [parameter(Mandatory=$true)]
        [string] $YubiKeyId
    )
    $provider = [RoyalCommon.Server.RoyalServer.MfaProvider]::Yubikey

    _AddMfaUser -Config $Config -Sid $Sid -Provider $provider -Username $Username -Comment $Comment -CacheSuccessFor $CacheSuccessFor `
        -RequireDocStore $requireDocStore -RequireSecureGateway $requireSecureGateway -YubiKey_YubiKeyId $YubiKeyId

}

<#
    .Description
    The Add-DuoUser function enrolls a new MFA user for the DUO provider.
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
    .PARAMETER Sid
    The user's SID.
    .PARAMETER Username
    The user's name.
    .PARAMETER Comment
    Comment for the user entry
    .PARAMETER CacheSuccessFor
    The CacheSuccessFor as a string representation of the DotNet Timespan, e.g. "00:30:00" for 30 mins
    .PARAMETER RequireDocStore
    An optional boolean to require the MFA for Document Store access. Defaults to false.
    .PARAMETER RequireSecureGateway
    An optional boolean to require the MFA for Secure Gateway. Defaults to false.
    .PARAMETER DuoUserId
    DUO internal user id
    
#>
function Add-DuoUser {
    param (       
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config,
        [parameter(Mandatory=$true)]
        [string] $Sid,
        [parameter(Mandatory=$true)]
        [string] $Username,
        [string] $Comment,
        [string] $CacheSuccessFor = $defaultCacheSuccessFor,
        [bool] $RequireDocStore = $false,
        [bool] $RequireSecureGateway = $false,
        [parameter(Mandatory=$true)]
        [string] $DuoUserId
    )
    $provider = [RoyalCommon.Server.RoyalServer.MfaProvider]::Duo

    _AddMfaUser -Config $Config -Sid $Sid -Provider $provider -Username $Username -Comment $Comment -CacheSuccessFor $CacheSuccessFor `
        -RequireDocStore $requireDocStore -RequireSecureGateway $requireSecureGateway -Duo_DuoUserId $DuoUserId
}

<#
    .Description
    The Set-Mfa function changes attributes of an existing MFA user configuration
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
    .PARAMETER Sid
    The user's SID.
    .PARAMETER Username
    The user's name.
    .PARAMETER Comment
    Comment for the user entry
    .PARAMETER Provider
    MFA Provider the user entry
    .PARAMETER CacheSuccessFor
    The CacheSuccessFor as a string representation of the DotNet Timespan, e.g. "00:30:00" for 30 mins
    .PARAMETER RequireDocStore
    An optional boolean to require the MFA for Document Store access. Defaults to false.
    .PARAMETER RequireSecureGateway
    An optional boolean to require the MFA for Secure Gateway. Defaults to false.
    .PARAMETER SelfServiceAllowed
    An optional boolean to require a self services workflow for the user. Defaults to false.
    Self-Service can be done here: https://<ROYAL-SERVER-URL>:<PORT>/mfa/totp for the user
    .PARAMETER SelfServiceVerified
    An optional boolean to set if SelfService was verified by the user
    .PARAMETER DuoUserId
    An optional parameter for the DUO internal user id
    .PARAMETER YubikeyId
    An optional parameter for the Id of the Yubikey
#>
function Set-MfaUser {
    param (       
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config,
        [parameter(Mandatory=$true)]
        [string] $MfaId,
        [parameter(Mandatory=$true)]
        [string] $Sid,
        [parameter(Mandatory=$true)]
        [string] $Username,
        [string] $Comment,
        [string] $Provider,
        [string] $CacheSuccessFor,
        [bool] $RequireDocStore = $false,
        [bool] $RequireSecureGateway = $false,
        [bool] $SelfServiceAllowed = $false,
        [bool] $SelfServiceVerified = $false,
        [string] $DuoUserId,
        [string] $YubiKeyId
    )


    $argz = @{
        "MfaID" = $MfaId
        "PrincipalSID" = "@{$Sid}"
        "Username" = $Username
        "ModifiedBy" = "$env:USERDOMAIN\$env:UserName"
        "Comment" = "$Comment"
        "Provider" = $Provider
        "CacheSuccessFor" = $CacheSuccessFor
        "RequireDocStore" = $requireDocStore
        "RequireSecureGateway" = $requireSecureGateway
    }

    switch ($Provider) {
        "Generic_TOTP"   { 
            $argz["Issuer"] = "RoyalServer-$env:COMPUTERNAME"
            $argz["Label"] = "$Username@RoyalServer-$env:COMPUTERNAME"
            $argz["SelfServiceAllowed"] = $SelfServiceAllowed 
            $argz["SelfServiceVerified"] = $SelfServiceVerified
            }
        "DUO"  { 
            $argz["Duo_UserId"] = $DuoUserId
            }
        "Yubikey" { 
            $argz["YubiKey_YubiKeyId"] = $YubiKeyId 
            }
        default { throw "Unknown MFA Provider" }
    }

    Invoke-RoyalServerCommand `
        -ModuleID RoyalServerManagement `
        -Command "EditUserMfaConfig" `
        -Arguments $argz `
        -DestinationHost $config.Host `
        -RoyalServerConfig $config
}


<#
    .Description
    The Remove-MfaUser function deletes a configured MFA user. 
    Use Get-TotpUsers to get the information for this commandlet.
    .PARAMETER MfaID
    The id of the user's MFA configuration entry.
    .PARAMETER Username
    The username corresponding to the user's MFA configuration entry.
    .PARAMETER Sid
    The SID corresponding to the user's MFA configuration entry.
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
#>
function Remove-MfaUser {
     param (
         [parameter(Mandatory=$true)]
         [string] $MfaId,
         [parameter(Mandatory=$true)]
         [string] $Username,
         [parameter(Mandatory=$true)]
         [string] $Sid,
         [parameter(Mandatory=$true)]
         [RoyalServer.PowerShell.RoyalServerConfig] $Config
     )
     
     $argz = @{
        "MfaID" = $MfaId
        "PrincipalSID" = "@{$Sid}"
        "Username" = $Username
        "ModifiedBy" = "$env:USERDOMAIN\$env:UserName"
     }

     Write-Host "Removing MFA enrollment of user $userName ..."

     Invoke-RoyalServerCommand `
        -ModuleID RoyalServerManagement `
        -Command "DeleteUserMfaConfig" `
        -Arguments $argz `
        -DestinationHost $Config.Host `
        -RoyalServerConfig $Config
}

<#
    .Description
    The Get-MfaUser function lists MFA user configurations
    .PARAMETER Config
    The RoyalServerConfig used to execute the command.
    .PARAMETER FilterByMfaProvider
    Filter the returned rows by the specified Provider: 1=TOTP, 2=Yubikey, 3=Duo
#>
function Get-MfaUser() {
    param (
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config,
        [parameter(Mandatory=$false)]
        [string] $FilterByMfaProvider # 1= TOTP, 2=Yubikey, 3=Duo
    )
    $response = Invoke-RoyalServerCommand `
        -ModuleID RoyalServerManagement `
        -Command "GetUserMfaConfiguration" `
        -DestinationHost $Config.Host `
        -RoyalServerConfig $Config

    return _FilterByMfaType $response
}

# Exported Helper Functions
function Get-AccountSid {
    param (       
        [parameter(Mandatory=$true)]
        [string] $Username
    )
    $objUser = New-Object System.Security.Principal.NTAccount($Username)
    try {
        $sid = ($objUser.Translate([System.Security.Principal.SecurityIdentifier])).Value
    }
    catch {
        Write-Error "Exception caught while reading SID for ${Username}: $($_.Exception.Message)"
        exit 1
    }
    $sid
}

# Internal helper functions
function Get-ProviderString()
{
        param (
        [parameter(Mandatory=$true)]
        [string] $Provider
        )
        switch ($Provider) {
        "1"   { 
            return "Generic_TOTP"
            }
        "3"  { 
            return "DUO"
            }
        "2" { 
            return "Yubikey"
            }
        default { throw "TranslateProvider(): Unknown MFA Provider" }
    }
}
function _FilterByMfaType()
{
    param (
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerPowerShellResponse] $Response,
        [parameter(Mandatory=$false)]
        [string] $FilterByMfaProvider # 1= TOTP, 2=Yubikey, 3=Duo
    )
    $mfaUsers = New-Object System.Collections.ArrayList
    foreach($mfaUser in $Response.Responses[0].Result) {
        $mfaProvider = $mfaUser["Provider"] 
        
        #filter by provider type if specified
        if($FilterByMfaProvider -and $mfaProvider -ne $FilterByMfaProvider) { 
            continue
        }
        $mfaUsers.Add($mfaUser) > $null
    }
    return $mfaUsers  
}
function _AddMfaUser {
    param (       
        [parameter(Mandatory=$true)]
        [RoyalServer.PowerShell.RoyalServerConfig] $Config,
        [parameter(Mandatory=$true)]
        [string] $Sid,
        [parameter(Mandatory=$true)]
        [string] $Provider,
        [parameter(Mandatory=$true)]
        [string] $Username,
        [string] $Comment,
        [string] $CacheSuccessFor = $defaultCacheSuccessFor,
        [bool] $RequireDocStore = $false,
        [bool] $RequireSecureGateway = $false,
        [bool] $SelfServiceAllowed = $false,
        [string] $Duo_DuoUserId,
        [string] $YubiKey_YubiKeyId
    )
    
        $argz = @{
            "PrincipalSID" = $Sid
            "Username" = $Username
            "Comment" = $Comment
            "ModifiedBy" = "$env:USERDOMAIN\$env:UserName"
            "Provider" = $Provider
            "Issuer" = "RoyalServer-$env:COMPUTERNAME"
            "Label" = "$Username@RoyalServer-$env:COMPUTERNAME"
            "CacheSuccessFor" = $CacheSuccessFor
            "RequireDocStore" = $requireDocStore
            "RequireSecureGateway" = $requireSecureGateway
            "SelfServiceAllowed" = $SelfServiceAllowed 
            "Duo_UserId" = $Duo_DuoUserId
            "YubiKey_YubiKeyId" = $Yubikey_YubikeyId
        }

        Invoke-RoyalServerCommand `
            -ModuleID RoyalServerManagement `
            -Command "EnrollUserMfaConfig" `
            -Arguments $argz `
            -DestinationHost $config.Host `
            -RoyalServerConfig $config
}



# Exporting Public Functions
Export-ModuleMember -Function Get-TotpUser
Export-ModuleMember -Function Get-DuoUser
Export-ModuleMember -Function Get-YubikeyUser
Export-ModuleMember -Function Get-MfaUser

Export-ModuleMember -Function Add-TotpUser
Export-ModuleMember -Function Add-YubikeyUser
Export-ModuleMember -Function Add-DuoUser

Export-ModuleMember -Function Remove-MfaUser
Export-ModuleMember -Function Set-MfaUser

Export-ModuleMember -Function Get-AccountSid
Export-ModuleMember -Function Get-ProviderString
