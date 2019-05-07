<#
.SYNOPSIS
  Checks your document passwords against Have I Been Pwned.
.DESCRIPTION
  This script allows you to check all your document passwords against the famous and
  great service called "Have I been pwned?". More information about this service can
  be found at the official site at: https://haveibeenpwned.com

  For your own security not your full passwords will be submitted to HIBP. The first
  5 letters from each passwords are going to be hashed using SHA-1 and submitted to
  the HIBP-API. Afterwards the returned dataset will be checked if your full SHA-1
  hashed password is within the returned list. This way your full password will
  never leave your local machine.

  Good luck that there are no matches! If so - taking action is recommended!
.INPUTS
  The only required parameter is the path to the document file.
.OUTPUTS
  A list of the objects (the object names, not the actual passwords) which are found in the HIBP dataset.
.PARAMETER File
  The path to your document file.
.PARAMETER EncryptionPassword
  The Encryption password of the specified document, if required.
.PARAMETER LockdownPassword
  The Lockdown password of the specified document, if required.
.EXAMPLE
  C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz"
.EXAMPLE
  C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz" -EncryptionPassword "EncryptionP@ssw0rd"
.EXAMPLE
  C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz" -EncryptionPassword "EncryptionP@ssw0rd" -LockdownPassword "LockdownP@ssw0rd"
.NOTES
  Name:           Check-DocumentPasswordsHIBP
  Version:        0.1.2
  Author:         Patrik Kernstock
  Copyright:      (C) 2018 code4ward GmbH
  Creation Date:  April 25, 2018
  Modified Date:  May 7, 2019
  Changelog:      For exact script changelog please check out the git commits history at:
                  https://github.com/royalapplications/scripts/commits/master/powershell/Check-DocumentPasswordsHIBP/Check-DocumentPasswordsHIBP.ps1
  Support:        For support please check out the "Support" section in the README file here:
                  https://github.com/royalapplications/scripts/tree/master/README.md#support
  Credits:        + To mrik23 on GitHub for inspiration how to do HIBP-API calls (https://gist.github.com/mrik23/e8efe6dc9cdfe62c9d0bb84dc25288fa)
                  + Troy Hunt for his great HaveIBeenPwned.com service! Give him out a donation if you appreciate his service.
.LINK
  https://github.com/royalapplications/scripts/commits/master/powershell/Check-DocumentPasswordsHIBP/
#>

## PARAMETERS
param(
    [CmdletBinding()]

    # File path to document. Default: None.
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [String] $File,

    # Encryption Password. Default: Null.
    [Parameter(Mandatory=$false)]
    $EncryptionPassword = $null,

    # Lockdown Password. Default: Null.
    [Parameter(Mandatory=$false)]
    $LockdownPassword = $null
)

### OTHERS
# load module: Royal TS.
if (Get-Module -ListAvailable RoyalDocument.PowerShell) {
    # Check if module is available, if so, load it. This is when module got installed through PSGallery.
    Import-Module RoyalDocument.PowerShell

} else {
    # If not, we try the legacy way.
    $psModulePaths = @()
    $psModulePaths += Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Royal TS V5\RoyalDocument.PowerShell.dll'
    $psModulePaths += Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'code4ward.net\Royal TS V4\RoyalDocument.PowerShell.dll'
    foreach ($psModulePath in $psModulePaths) {
        if (Test-Path $psModulePath) {
            Import-Module $psModulePath
            break
        }
    }
}

if (!(Get-Module "RoyalDocument.PowerShell")) {
    Write-Error "Required RoyalDocument module not loaded."
    Write-Output "Please make sure you have either the PowerShell module installed through"
    Write-Output "PSGallery (recommended), or have an older Royal TS release installed which still"
    Write-Output "ships the PowerShell module with the installer. See more info at PSGallery site at:"
    Write-Output "https://www.powershellgallery.com/packages/RoyalDocument.PowerShell/"
    Write-Output "Installation using PSGallery: $ Install-Module -Name RoyalDocument.PowerShell"
    Write-Output "Aborting."
    exit
}

# sanity checks
if (!(Test-Path $File)) {
    Write-Error "Royal Document '$File' does not exist. Please provide a existing file. Aborting." -Category OpenError -ErrorAction Stop
}
$RoyalDocFile = $File

# check if Encryption and Lockdown Password as Secured Strings
if ($null -ne $EncryptionPassword -and $EncryptionPassword -isnot [SecureString]) {
    $EncryptionPassword = $EncryptionPassword | ConvertTo-SecureString -Force -AsPlainText
}
if ($null -ne $LockdownPassword -and $LockdownPassword -isnot [SecureString]) {
    $LockdownPassword = $LockdownPassword | ConvertTo-SecureString -Force -AsPlainText
}

# if lockdown password specified, but no encryption password, something will go wrong later on anyway. so we just abort here.
if ($null -ne $LockdownPassword -and $null -eq $EncryptionPassword) {
    Write-Error "When providing lockdown password the encryption password is required too. Aborting." -Category OpenError -ErrorAction Stop
}

# To stay on the safe side: Force TLS 1.2 for upcoming API requests.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Function to create SHA-1 hash from password string
Function Get-StringHashSHA1()
{
    # Credits and Thanks to mrik23 here! See credits above.
    [CmdletBinding()]
    Param (
          [Parameter(Mandatory=$True)]
          [String] $inputString
    )

    $Private:outputHash = [string]::Empty
    $hasher = New-Object -TypeName "System.Security.Cryptography.SHA1CryptoServiceProvider"
    $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($inputString)) | ForEach-Object {
        $outputHash += $_.ToString("x2")
    }

    return $outputHash.ToUpper()
}

# Function to check the partial password hash against HIBP
function CheckPasswordWithHIBP()
{
    param(
        [string] $stringHash
    )

    # this is the hashPrefix what is being sent over to the HIBP API
    $hashPrefix = $stringHash.Substring(0, 5)
    # that is the rest of the string after the 5th char
    $hashSuffix = $stringHash.Substring(5)

    # Invoking the web request to HIBP
    try {
        $response = Invoke-RestMethod -Uri "https://api.pwnedpasswords.com/range/$($hashPrefix)" -Method Get -ErrorVariable errorRequest
    }
    catch {
        return "[!] Error checking password of object '$($objName)': $($errorRequest)"
    }

    # If we got any response from the API...
    if ($null -ne $response) {
        $findHashSuffix = $response.Contains($hashSuffix)
        if ($findHashSuffix -eq $true) {
            $result = $response.Substring(
                $response.IndexOf($hashSuffix),
                ($response.IndexOf("`r`n", $response.IndexOf($hashSuffix)) - $response.IndexOf($hashSuffix))
            )
            $resultCount = ($result.Split(":"))[1]
            # oh noes. we found something.
            return [int] $resultCount
        }
        else {
            # hash prefix returned something, but not expected password
            return [int] 0
        }
    }
    else {
        # hash prefix returned zero results from HIBP
        return [int] 0
    }

    return "unknown error"
}

# prepare some stuff.
Write-Verbose "+ Preparing..."
Write-Progress -Activity "Initialization" -Status "Loading data..." -PercentComplete 0
# create store (container for any documents)
$store = New-RoyalStore -UserName "HIBP-Checker"

# here we have a list of hashed passwords and the object ids using it
$docHashedPasswords = @{}
# here we have a list of all objects with ID and name, which contain any passwords
$docObjNames = @{}

# open document
Write-Verbose "+ Loading document..."
$doc = Open-RoyalDocument -Store $store -FileName $RoyalDocFile -Password $EncryptionPassword -LockdownPassword $LockdownPassword
# check if loading worked
if ($null -eq $doc) {
    Write-Error -Message "Failed loading document. Missing Encryption/Lockdown password? Please check. Aborting." -Category OpenError -ErrorAction Stop
}

Write-Verbose "+ Loading password properties..."
# get all objects with passwords
$passwords = $doc.GetAllPasswordProperties()
$totalPasswordPropsMax = @($passwords).Count
$passwords | ForEach-Object {
    # HINT: no progress bar here as it noticable slows down the process here.
    # get the object.
    $obj = $_.Item1
    # get the cleartext password
    $clearPwd = $obj.GetPropertyValue($_.Item2)
    # check if passwords are not empty and are not any CustomProperties
    # INFO: CustomProperties can not be iteriated with PS-API as of now
    # TODO: REMEMBER OBJECT PROPERTY NAME
    if ($clearPwd -ne "" -and $_.Item2.Name -ne "CustomProperties") {
        # remember name for later result list
        $docObjNames[$obj.ID] = $obj.Name
        # now only save hashed password into memory
        $hashedPwd = Get-StringHashSHA1 -inputString $clearPwd
        # get rid of cleartext passwords in memory ASAP
        $clearPwd = $null
        # check if we already have that one hashed password in our list
        if ($docHashedPasswords[$hashedPwd] -eq $null) {
            # nope, we don't. create a new array here.
            $docHashedPasswords[$hashedPwd] = @()
        }
        # add the object ID to the list, so we know which objects are using the hashed password
        $docHashedPasswords[$hashedPwd] += $obj.ID
    }
}
# clear the passwords variable from memory ASAP
$passwords = $null
Write-Verbose "Total scanned password properties: $totalPasswordPropsMax"

# output some stats
# when using get_Count() here we get the actual size of the hashtable, duplicate passwords removed.
$totalPasswords = $docHashedPasswords.get_Count()
$totalObjects = $docObjNames.get_Count()
Write-Host "Total of unique passwords to check: $totalPasswords"
Write-Host "Total of objects with passwords found: $totalObjects"

# now we're checking the passwords...
Write-Verbose "+ Checking passwords against HIBP..."
$totalMatches = 0
$hashedPwdCount = 0
$docHashedPasswords.Keys | ForEach-Object {
    $hashedPwdCount++
    Write-Host "Checking password $hashedPwdCount/$totalPasswords..." -ForegroundColor Blue

    # progress bar. yaay!
    Write-Progress -Activity "Checking password property $hashedPwdCount of $totalPasswords..." -Status "Processing..." -PercentComplete (($hashedPwdCount / $totalPasswords) * 100)

    $hashMatches = CheckPasswordWithHIBP -stringHash $_
    # if we do not get any integer back, anything wrong happend.
    if ($hashMatches -isnot [int]) {
        Write-Error -Message " Error ocurred while checking: $hashMatches" -Category InvalidResult
        continue
    }

    # result, but 0 records found. Reason to be happy!
    if ($hashMatches -le 0) {
        Write-Host "  No matches. Good!" -ForegroundColor Green
    } else {
        # oh no, we got pwned. tell the user the bad truth... including how often and which objects are affected.
        $totalMatches += $hashMatches
        Write-Host " Password has been pwned ${hashMatches}x." -ForegroundColor Red
        Write-Host "  Objects affected:" -ForegroundColor Magenta
        $docHashedPasswords.Item($_) | ForEach-Object {
            Write-Host "   - $($docObjNames[$_])"
        }
    }
}

# ...and we're done.
Write-Verbose "+ Password check done."
Write-Progress -Activity "Scan finished" -Status "Work complete." -PercentComplete 100
if ($totalMatches -gt 0) {
    Write-Host "In total your passwords has been pwned ${totalMatches}x." -ForegroundColor Red
    Write-Host "Changing affected passwords is strongly recommended!" -ForegroundColor Red
} else {
    Write-Host "No matches found! Your used document passwords were not pwned. Yaay!" -ForegroundColor Green
}

# ...and we're done.
Write-Verbose "+ Done."

# FIN
