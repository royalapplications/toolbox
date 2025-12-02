<#
.SYNOPSIS
    This script helps separating Credentials from Connections 
    objects for easier sharing with a team.

.DESCRIPTION
    This script
      1. Finds all objects that have specified a credential 
         either directly or by ID
      2. Create a new Credential with Name, Username/Pwd and 
         reference this by Name in Creds_Stripped
      3. Create a new Credential with Name only and reference 
         this by Name in CredsEmpty_Strippedf
      4. Save a set of new Documents
         - <original_name>_Stripped.rtsz (contains only 
            Connections with Credentials Referenced By Name
         - <original_name>_Creds_Stripped.rtsz (contains the 
            separated Credentials with UserName/Pwd)
         - <original_name>_CredsEmpty_Stripped.rtsz (contains 
            the separated Credentials w/o UserName/Pwd). This 
            file is inteded to be sent to colleagues to fill 
            in their own Credentials 

    This software is provided ‘as is’, without any warranties 
    or representations of any kind, whether express or implied, 
    including but not limited to warranties of merchantability, 
    fitness for a particular purpose, or non-infringement.

    Remarks:
        - This script assumes that any referenced credentials 
          are in the source file.
        - The source .rtsz Document is never changed.
        - Any credentials that are not referenced within the 
          source document will be moved
        - The default Suffix "Stripped" can be changed by 
          editing the variable $newFileSuffix
        - The IDs of the source Document objects stay the same 
          when moved, so you cannot open the source and stripped 
          Document at the same time.

.CHANGELOG
    1.0.6 - 2025-10-30 - ms - duplicates handling improved 
    1.0.5 - 2025-10-29 - ms - Updated RoyalCredential handling
                              warn on additional MFA configuration
    1.0.4 - 2025-10-28 - ms - Fixed some Credential references
                              Output refinements
                              Private Key Warnings added
                              Documentation simplified
    1.0.3 - 2025-10-27 - ms - Ask before overwriting files, 
                              Fixed Trashcan Cleanup
    1.0.2 - 2025-10-25 - ms - RoyalKeySequenceTask added
    1.0.1 - 2025-10-24 - ms - Royal Server and Secure Gateway 
                              Credential handling added
    1.0.0 - 2025-10-22 - ms - Initial release.

.PARAMETER FileName
    Royal Document File Name

.PARAMETER DebugLogging
    This parameter defines the Log Level

.PARAMETER Password
    This parameter specifies the Documemnt Password

.PARAMETER LockdownPassword
    This parameter specifies the Lockdown Password

.PARAMETER Force
    This parameter will overwrite the generated .rtsz File
    without asking

.EXAMPLE
    .\Split-Credentials.ps1 -FileName source.rtsz -DebugLogging -Force

.NOTES
    Author:        RoyalApps/Michael Seirer (ms)
    Requires:      PowerShell 5.1+ or PowerShell Core 7+, 
                   RoyalDocument.Powershell module
#>
#------------------------------------------------------------
#region [ Parameters ]
#------------------------------------------------------------

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "FileName of the source Royal Document.")]
    [string]$FileName,
    [Parameter(Mandatory=$false)]
    [string]$Password,
    [Parameter(Mandatory=$false)]
    [string]$LockdownPassword,
    [Parameter(Mandatory=$false)]
    [switch]$DebugLogging,
    [switch]$Force #overwrite generated .rtsz file
)

#endregion Parameters
#------------------------------------------------------------

$ErrorActionPreference = "Stop"

Import-Module RoyalDocument.Powershell -ErrorAction Stop

$ScriptName = $MyInvocation.MyCommand.Name
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

Clear-Host

$clonedIds = @{}

#------------------------------------------------------------
#region [ Functions ]
#------------------------------------------------------------
function Get-NewGuid
{
    $g = New-Guid
    return $g.Guid.ToString()
}
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("DBG", "INF", "WRN", "ERR")]
        [string]$Level = "INF"
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "[$timestamp][$Level] $Message"

    switch ($Level) {
        "DBG" { if($DebugLogging -eq $true) { Write-Host $logMessage -ForegroundColor Gray } }
        "INF"  { Write-Host $logMessage -ForegroundColor Cyan }
        "WRN"  { Write-Host $logMessage -ForegroundColor Yellow }
        "ERR" { Write-Host $logMessage -ForegroundColor Red }
    }
}

function Open-RoyalDocumentFile
{
    param (
        $fileName
    )
    if($Password.Length)
    {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        if($LockdownPassword)
        {
            $SecureLockdownPassword = ConvertTo-SecureString $LockdownPassword -AsPlainText -Force
            $doc = Open-RoyalDocument -Store $store -FileName $fileName -Password $SecurePassword -LockdownPassword $SecureLockdownPassword
        }
        else
        {
            $doc = Open-RoyalDocument -Store $store -FileName $fileName -Password $SecurePassword
        }
    }
    else
    {
        $doc = Open-RoyalDocument -Store $store -FileName $fileName
    }
    $doc
}

function Generate-CredentialName
{
    param ($referenceObject,
        $CredentialUsernamePropertyName)

    if($($referenceObject.GetType().Name) -eq "RoyalCredential")
    {
        $tempCredName = $referenceObject.Name;
    }
    else
    {
        $tempCredName = $($referenceObject.$CredentialUsernamePropertyName);
    }
    
    if($tempCredName -eq "") { $tempCredName = "$tempCredName $($referenceObject.Name)" }
    if($tempCredName -eq "")
    {
        $g = New-Guid
        $tempCredName = -join ($tempCredName, $g )
    }
    return $tempCredName.Trim()
}

function Update-Credential
{
    param (
        $Credential,
        $ReferenceName,
        $CredentialMode,
        $CredentialModePropertyName,
        $CredentialNamePropertyName,
        $CredentialUsernamePropertyName,
        $CredentialPasswordPropertyName
        )

    $Credential.($CredentialModePropertyName) = $CredentialMode
    $Credential.$($CredentialNamePropertyName) = $ReferenceName
    $Credential.$($CredentialUsernamePropertyName) = '' # remove possible old values
    $Credential.$($CredentialPasswordPropertyName) = '' # remove possible old values
    

    Write-Log -Message "    -> Updated Credential '$($Credential.Name)' to reference Credential with name '$ReferenceName'." -Level INF
   
}

function Update-ExistingCredential
{
    param (
        $referencedObject,
        $CredentialMode,
        $CredentialModePropertyName,
        $CredentialNamePropertyName,
        $CredentialUsernamePropertyName,
        $CredentialPasswordPropertyName
        )

    # look up
    $configuredCredentialId = Get-ConfiguredCredentialId -referencedObject $o
    $newCredentialId = $clonedIds[$configuredCredentialId]
    $Credential = Get-RoyalObject -Folder $docCreds -Id $newCredentialId

    if($null -eq $Credential)
    {
               
        Write-Log "Object '$($referencedObject.Name)' references an unknown Credential - Ignoring it." -Level WRN
        continue;
    }
    
    if($null -ne $(Find-RoyalCredential -cred $Credential))
    {
        # such a credential is already existing
        # update original object to reference cred by name
        Update-Credential `
            -Credential $referencedObject `
            -ReferenceName $Credential.Name `
            -CredentialMode $CredentialMode `
            -CredentialModePropertyName $CredentialModePropertyName `
            -CredentialNamePropertyName $CredentialNamePropertyName `
            -CredentialUsernamePropertyName $CredentialUsernamePropertyName `
            -CredentialPasswordPropertyName $CredentialPasswordPropertyName
    }
    else
    {
         Create-ReferencedCredentials `
            -CredName $Credential.Name `
            -CredentialUserName $Credential.UserName `
            -CredentialPassword $Credential.Password `
            -ReferencingObject $referencedObject `
            -CredentialMode $CredentialMode `
            -CredentialModePropertyName $CredentialModePropertyName `
            -CredentialNamePropertyName $CredentialNamePropertyName `
            -CredentialUsernamePropertyName $CredentialUsernamePropertyName `
            -CredentialPasswordPropertyName $CredentialPasswordPropertyName
    }
}

function Get-ConfiguredCredential
{
    param ($referencedObject)

    $cred = $null
    if($referencedObject.GetType().Name -eq "RoyalManagementEndpoint" )
    {
        $cred = Get-RoyalObject -Folder $doc -Id $referencedObject.RoyalServerCredentialID
    }
    elseif($referencedObject.GetType().Name -eq "RoyalSecureGateway" )
    {
        $cred = Get-RoyalObject -Folder $doc -Id $referencedObject.SecureGatewayCredentialID
    }
    else
    {
        $cred = Get-RoyalObject -Folder $doc -Id $o.CredentialId.ToString()
    }
    $cred
}

function Get-ConfiguredCredentialId
{
    param ($referencedObject)

    if($referencedObject.GetType().Name -eq "RoyalManagementEndpoint" )
    {
        return $referencedObject.RoyalServerCredentialID.ToString()
    }
    elseif($referencedObject.GetType().Name -eq "RoyalSecureGateway" )
    {
        return $referencedObject.SecureGatewayCredentialID.ToString()
    }
    else
    {
        return $o.CredentialId.ToString()
    }
}

function Create-ReferencedCredentials
{
    param (
        $CredName,
        $CredentialUserName,
        $CredentialPassword,
        $ReferencingObject,
        $CredentialMode,
        $CredentialModePropertyName,
        $CredentialNamePropertyName,
        $CredentialUsernamePropertyName,
        $CredentialPasswordPropertyName
        )

    # Create new Credential within the Credentials Document including the UserName and Pwd
    $tempCred = New-RoyalObject -Folder $docCreds -Type RoyalCredential -Name $CredName
    $tempCred.UserName = $CredentialUserName
    $tempCred.Password = $CredentialPassword

    # Create new Cred within the Credentials Document w/o UserName and Pwd
    $tempCred1 = New-RoyalObject -Folder $docCredsEmpty -Type RoyalCredential -Name $CredName

    Write-Log "    Created new Credential '$($tempCred.Name)'" -Level DBG

    Update-Credential `
        -Credential $ReferencingObject `
        -ReferenceName $CredName `
        -CredentialMode $CredentialMode `
        -CredentialModePropertyName $CredentialModePropertyName `
        -CredentialNamePropertyName $CredentialNamePropertyName `
        -CredentialUsernamePropertyName $CredentialUsernamePropertyName `
        -CredentialPasswordPropertyName $CredentialPasswordPropertyName
}

function Clone-RoyalCredential
{
    param (
        $cred
        )

    # cloning Credential 
    $newCred = New-RoyalObject -Folder $docCreds -Type RoyalCredential -Name $cred.Name
    $newCred.UserName = $cred.UserName
    $newCred.Password = $cred.Password
    $newCred.AutoFillDelay = $cred.AutoFillDelay
    $newCred.AutoFillMapping = $cred.AutoFillMapping
    $newCred.ColorFromParent = $cred.ColorFromParent
    $newCred.CustomImageList = $cred.CustomImageList
    $newCred.Description = $cred.Description
    $newCred.Favorite = $cred.Favorite
    $newCred.Passphrase = $cred.Passphrase
    $newCred.RetryAutoFillUntilSuccess = $cred.RetryAutoFillUntilSuccess
    $newCred.URL = $cred.URL
    $newCred.UserName = $cred.UserName
    $newCred.ColorName = $cred.ColorName
    $newCred.Color = $cred.Color
    $newCred.CustomImage = $cred.CustomImage
    $newCred.CustomImageName = $cred.CustomImageName
    $newCred.PrivateKeyMode = $cred.PrivateKeyMode
    $newCred.PrivateKeyPath = $cred.PrivateKeyPath
    $newCred.PrivateKeyContent = $cred.PrivateKeyContent
    $newCred.MfaConfiguration = $cred.MfaConfiguration
    $newCred.MfaProperty = $cred.MfaProperty
    $newCred.MfaTemplate = $cred.MfaTemplate
    
    #TODO Property MfaTotpGeneratorSecret is obsolete, update of powershell cmdlets needed
    $newCred.MfaTotpGeneratorSecret = $cred.MfaTotpGeneratorSecret
    #$newCred.MfaTotpSecret = $cred.MfaTotpSecret
    
    $newCred.MfaTotpGeneratorLabel = $cred.MfaTotpGeneratorLabel
    $newCred.MfaTotpGeneratorIssuer = $cred.MfaTotpGeneratorIssuer
    $newCred.MfaTotpGeneratorAlgorithm = $cred.MfaTotpGeneratorAlgorithm
    $newCred.MfaTotpGeneratorCodeLength = $cred.MfaTotpGeneratorCodeLength
    $newCred.MfaTotpGeneratorSecondsValid = $cred.MfaTotpGeneratorSecondsValid
    $newCred.Notes = $cred.Notes
    $newCred.NotesFromParent = $cred.NotesFromParent
    $newCred.CustomPropertiesFromParent = $cred.CustomPropertiesFromParent
    $newCred.CustomProperties = $cred.CustomProperties
    $newCred.CustomField1 = $cred.CustomField1
    $newCred.CustomField1FromParent = $cred.CustomField1FromParent
    $newCred.CustomField2 = $cred.CustomField2
    $newCred.CustomField2FromParent = $cred.CustomField2FromParent
    $newCred.CustomField3 = $cred.CustomField3
    $newCred.CustomField3FromParent = $cred.CustomField3FromParent
    $newCred.CustomField4 = $cred.CustomField4
    $newCred.CustomField4FromParent = $cred.CustomField4FromParent
    $newCred.CustomField5 = $cred.CustomField5
    $newCred.CustomField5FromParent = $cred.CustomField5FromParent
    $newCred.CustomField6 = $cred.CustomField6
    $newCred.CustomField6FromParent = $cred.CustomField6FromParent
    $newCred.CustomField7 = $cred.CustomField7
    $newCred.CustomField7FromParent = $cred.CustomField7FromParent
    $newCred.CustomField8 = $cred.CustomField8
    $newCred.CustomField8FromParent = $cred.CustomField8FromParent
    $newCred.CustomField9 = $cred.CustomField9
    $newCred.CustomField9FromParent = $cred.CustomField9FromParent
    $newCred.CustomField10 = $cred.CustomField10
    $newCred.CustomField10FromParent = $cred.CustomField10FromParent
    $newCred.CustomField11 = $cred.CustomField11
    $newCred.CustomField11FromParent = $cred.CustomField11FromParent
    $newCred.CustomField12 = $cred.CustomField12
    $newCred.CustomField12FromParent = $cred.CustomField12FromParent
    $newCred.CustomField13 = $cred.CustomField13
    $newCred.CustomField13FromParent = $cred.CustomField13FromParent
    $newCred.CustomField14 = $cred.CustomField14
    $newCred.CustomField14FromParent = $cred.CustomField14FromParent
    $newCred.CustomField15 = $cred.CustomField15
    $newCred.CustomField15FromParent = $cred.CustomField15FromParent
    $newCred.CustomField16 = $cred.CustomField16
    $newCred.CustomField16FromParent = $cred.CustomField16FromParent
    $newCred.CustomField17 = $cred.CustomField17
    $newCred.CustomField17FromParent = $cred.CustomField17FromParent
    $newCred.CustomField18 = $cred.CustomField18
    $newCred.CustomField18FromParent = $cred.CustomField18FromParent
    $newCred.CustomField19 = $cred.CustomField19
    $newCred.CustomField19FromParent = $cred.CustomField19FromParent
    $newCred.CustomField20 = $cred.CustomField20
    $newCred.CustomField20FromParent = $cred.CustomField20FromParent

    Write-Log "    Credential ID $($cred.Name) -> $($newCred.ID)" -Level INF

    return $newCred
}

function Find-RoyalCredential
{
    param (
        [RoyalDocumentLibrary.RoyalCredential]$cred
        )

    # checks if a Credential with the same properties is already existing
    # in $docCreds
    
    $tempCredName = Generate-CredentialName -referenceObject $cred -CredentialUsernamePropertyName "Username"
    $tempCred = Get-RoyalObject -Folder $docCreds -Name $tempCredName -Type RoyalCredential
    
    if($null -eq $tempCred)
    {
        $alternativeId = $clonedIds[$cred.ID];
        if($null -ne $alternativeId)
        {
            $tempCred = Get-RoyalObject -Folder $docCreds -ID alternativeId
        }
        
    }
    
    if($null -eq $tempCred)
    {
        return $null;
    }

    if($cred.AutoFillDelay -ne $tempCred.AutoFillDelay) { return $null; }
    if($cred.Password -ne $tempCred.Password) { return $null; }
    if($cred.AutoFillMapping -ne $tempCred.AutoFillMapping) { return $null; }
    if($cred.ColorFromParent -ne $tempCred.ColorFromParent) { return $null; }
    if($cred.CustomImageList -ne $tempCred.CustomImageList) { return $null; }
    if($cred.Description+"" -ne ""+$tempCred.Description) { return $null; }
    if($cred.Favorite -ne $tempCred.Favorite) { return $null; }
    if($cred.Passphrase -ne $tempCred.Passphrase) { return $null; }
    if($cred.RetryAutoFillUntilSuccess -ne $tempCred.RetryAutoFillUntilSuccess) { return $null; }
    if($cred.URL -ne $tempCred.URL) { return $null; }
    if($cred.ColorName -ne $tempCred.ColorName) { return $null; }
    if($cred.Color -ne $tempCred.Color) { return $null; }
    if($cred.CustomImage -ne $tempCred.CustomImage) { return $null; }
    if($cred.CustomImageName -ne $tempCred.CustomImageName) { return $null; }
    if($cred.PrivateKeyMode -ne $tempCred.PrivateKeyMode) { return $null; }
    if($cred.PrivateKeyPath -ne $tempCred.PrivateKeyPath) { return $null; }

    # PrivateKeyContent is a byte[]
    $areEqual = @(Compare-Object $cred.PrivateKeyContent $tempCred.PrivateKeyContent).Length -eq 0
    if(-not $areEqual) { return $null; } 
    
    if($cred.MfaConfiguration -ne $tempCred.MfaConfiguration) { return $null; }
    if($cred.MfaProperty -ne $tempCred.MfaProperty) { return $null; }
    if($cred.MfaTemplate -ne $tempCred.MfaTemplate) { return $null; }
    #TODO Property MfaTotpGeneratorSecret is obsolete, update of powershell cmdlets needed
    if($cred.MfaTotpGeneratorSecret -ne $tempCred.MfaTotpGeneratorSecret) { return $null; }
    #($cred.MfaTotpSecret -ne $tempCred.MfaTotpSecret) { return $null; }
    if($cred.MfaTotpGeneratorLabel -ne $tempCred.MfaTotpGeneratorLabel) { return $null; }
    if($cred.MfaTotpGeneratorIssuer -ne $tempCred.MfaTotpGeneratorIssuer) { return $null; }
    if($cred.MfaTotpGeneratorAlgorithm -ne $tempCred.MfaTotpGeneratorAlgorithm)  { return $null; }
    if($cred.MfaTotpGeneratorCodeLength -ne $tempCred.MfaTotpGeneratorCodeLength)  { return $null; }
    if($cred.MfaTotpGeneratorSecondsValid -ne $tempCred.MfaTotpGeneratorSecondsValid)  { return $null; }
    if($cred.Notes -ne $tempCred.Notes)  { return $null; }
    if($cred.NotesFromParent -ne $tempCred.NotesFromParent) { return $null; }
    if($cred.CustomPropertiesFromParent -ne $tempCred.CustomPropertiesFromParent) { return $null; }
    if($cred.CustomProperties -ne $tempCred.CustomProperties) { return $null; }
    if($cred.CustomField1 -ne $tempCred.CustomField1) { return $null; }
    if($cred.CustomField1FromParent -ne $tempCred.CustomField1FromParent) { return $null; }
    if($cred.CustomField2 -ne $tempCred.CustomField2) { return $null; }
    if($cred.CustomField2FromParent -ne $tempCred.CustomField2FromParent)  { return $null; }
    if($cred.CustomField3 -ne $tempCred.CustomField3) { return $null; }
    if($cred.CustomField3FromParent -ne $tempCred.CustomField3FromParent) { return $null; }
    if($cred.CustomField4 -ne $tempCred.CustomField4) { return $null; }
    if($cred.CustomField4FromParent -ne $tempCred.CustomField4FromParent) { return $null; }
    if($cred.CustomField5 -ne $tempCred.CustomField5) { return $null; }
    if($cred.CustomField5FromParent -ne $tempCred.CustomField5FromParent) { return $null; }
    if($cred.CustomField6 -ne $tempCred.CustomField6) { return $null; }
    if($cred.CustomField6FromParent -ne $tempCred.CustomField6FromParent) { return $null; }
    if($cred.CustomField7 -ne $tempCred.CustomField7) { return $null; }
    if($cred.CustomField7FromParent -ne $tempCred.CustomField7FromParent) { return $null; }
    if($cred.CustomField8 -ne $tempCred.CustomField8) { return $null; }
    if($cred.CustomField8FromParent -ne $tempCred.CustomField8FromParent) { return $null; }
    if($cred.CustomField9 -ne $tempCred.CustomField9) { return $null; }
    if($cred.CustomField9FromParent -ne $tempCred.CustomField9FromParent) { return $null; }
    if($cred.CustomField10 -ne $tempCred.CustomField10) { return $null; }
    if($cred.CustomField10FromParent -ne $tempCred.CustomField10FromParent) { return $null; }
    if($cred.CustomField11 -ne $tempCred.CustomField11) { return $null; }
    if($cred.CustomField11FromParent -ne $tempCred.CustomField11FromParent) { return $null; }
    if($cred.CustomField12 -ne $tempCred.CustomField12) { return $null; }
    if($cred.CustomField12FromParent -ne $tempCred.CustomField12FromParent) { return $null; }
    if($cred.CustomField13 -ne $tempCred.CustomField13)  { return $null; }
    if($cred.CustomField13FromParent -ne $tempCred.CustomField13FromParent) { return $null; }
    if($cred.CustomField14 -ne $tempCred.CustomField14) { return $null; }
    if($cred.CustomField14FromParent -ne $tempCred.CustomField14FromParent) { return $null; }
    if($cred.CustomField15 -ne $tempCred.CustomField15) { return $null; }
    if($cred.CustomField15FromParent -ne $tempCred.CustomField15FromParent) { return $null; }
    if($cred.CustomField16 -ne $tempCred.CustomField16) { return $null; }
    if($cred.CustomField16FromParent -ne $tempCred.CustomField16FromParent) { return $null; }
    if($cred.CustomField17 -ne $tempCred.CustomField17) { return $null; }
    if($cred.CustomField17FromParent -ne $tempCred.CustomField17FromParent) { return $null; }
    if($cred.CustomField18 -ne $tempCred.CustomField18) { return $null; }
    if($cred.CustomField18FromParent -ne $tempCred.CustomField18FromParent) { return $null; }
    if($cred.CustomField19 -ne $tempCred.CustomField19) { return $null; }
    if($cred.CustomField19FromParent -ne $tempCred.CustomField19FromParent) { return $null; }
    if($cred.CustomField20 -ne $tempCred.CustomField20) { return $null; }
    if($cred.CustomField20FromParent -ne $tempCred.CustomField20FromParent) { return $null; }
    
    return $tempCred;
}


function Confirm-FileOverwrite {
    param(
        [string]$RtszFile,
        [switch]$Force
    )

    if ( (Test-Path $RtszFile) -and (-not $Force)) {
        $response = Read-Host "File '$RtszFile' already exists. Overwrite? (y/n)"
        return ($response -eq 'y')
    }
    return $true
}
function Contains-SensitiveInformation
{
    param (
        $o
    )

    if( $o.CredentialPassphrase -or `
        $o.Passphrase -or `
        $o.CredentialKeyContent -or `
        $o.PrivateKeyContent -or `
        $o.MfaConfiguration -or `
        $o.MfaProperty -or `
        $o.MfaTemplate -or `
        #TODO Property MfaTotpGeneratorSecret is obsolete, update of powershell cmdlets needed
        $o.MfaTotpGeneratorSecret -or `
        #$o.MfaTotpSecret -or `
        $o.MfaTotpGeneratorLabel -or `
        $o.MfaTotpGeneratorIssuer -or `
        $o.MfaTotpGeneratorAlgorithm -or `
        $o.MfaTotpGeneratorCodeLength -or `
        $o.MfaTotpGeneratorSecondsValid
    )
    {
        return $true;
    }
    return $false;
}


#endregion Functions
#------------------------------------------------------------


If(-not $FileName.EndsWith(".rtsz"))
{
    Write-Log "Specify a .rtsz file" -Level ERR
    Exit
}
If(-not (Test-Path $FileName))
{
    Write-Log "File not found: '$FileName'" -Level ERR
    Exit
}


#------------------------------------------------------------
#region [ Core Logic ]
#------------------------------------------------------------


Write-Log "Starting to split Credentials ..." -Level INF

$newFileSuffix = "Stripped"

$inputFile = Get-Item $FileName
$docFileName = $FileName
$docModifiedFileName = "$($inputFile.Basename)_$newFileSuffix.rtsz"
$credsFileName = "$($inputFile.Basename)_Creds_$newFileSuffix.rtsz"
$credsEmptyFileName = "$($inputFile.Basename)_CredsEmpty_$newFileSuffix.rtsz"
Write-Log "Original File: $FileName" -Level INF
Write-Log "New Royal Document w/o Credentials: $docModifiedFileName" -Level INF
Write-Log "New Royal Document with Credentials (Username+Passwords): $credsFileName" -Level INF
Write-Log "New Royal Document with empty Credentials: $credsEmptyFileName" -Level INF

# Splitted Files are existing already
if (-not (Confirm-FileOverwrite -RtszFile $credsFileName -Force:$Force)) { Write-Log "Aborting..." -Level INF; return }
if (-not (Confirm-FileOverwrite -RtszFile $credsEmptyFileName -Force:$Force)) { Write-Log "Aborting..." -Level INF; return }

Write-Log "Splitting Credentials started." -Level INF

    
$store = New-RoyalStore -UserName $env:USERNAME
$doc = Open-RoyalDocumentFile -fileName $docFileName

# Create a new Document only containing referenced Credentials for User (including the current PWDs if available)
$docCreds = New-RoyalDocument -Store $store -Name "Credentials of $env:USERNAME" -FileName $credsFileName

# Create new Document only containing referenced Credentials for other users (no PWDs)
$docCredsEmpty = New-RoyalDocument -Store $store -Name "Credentials of <t.b.d>" -FileName $credsEmptyFileName


# migrate all credentials first
Write-Log "Migrating existing Credentials ..." -Level INF
$existingCredentials = Get-RoyalObject -Folder $doc -Type RoyalCredential
foreach($existingCredential in $existingCredentials)
{
    # create a new cred in the destination document
    $newCred = Clone-RoyalCredential -cred $existingCredential
    
    #remember the origin
    $clonedIds[$existingCredential.ID.ToString()] = $newCred.ID.ToString()

    $store.DeleteRoyalObject($existingCredential)
    Write-Log "    -> Copied '$($existingCredential.Name)' '$($existingCredential.ID.ToString())'->'$($newCred.ID.ToString())'to new Document."
}
Write-Log "Migrating existing Credentials ... done." -Level INF

# handle all other object types
Write-Log "Migrating all other Object Types..." -Level INF
$ids = $doc.GetAllObjectIDs()
foreach($id in $ids)
{
    $o = Get-RoyalObject -Folder $doc -Id $id

    if($null -eq $o) { continue; }
    if($o.IsInTrash()) {continue;} #Ignore deleted objects

    Write-Log "Examining: '$($o.Name)' '$($o.ID)'" -Level DBG

    if($o.CredentialFromParent -eq $true) 
    {
        Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: CredentialFromParent=true."
        continue; 
    }

    # other sensitive information properties which are not supported
    if($(Contains-SensitiveInformation -o $o))
    {
        Write-Log "    '$($o.Name)' has additional sensitive Information (PK, MFA) - handle manually." -Level WRN
    }

    if($o.GetType().Name -eq "RoyalManagementEndpoint") #Royal Server Object
    {
        # handle Royal Server credential Info
        switch ($o.RoyalServerCredentialMode)
        {
            0 # Do not use any credentials
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Do Not Use Any Credentials'."
                }
            1
                {
                    # 1 = Specify username and password
                    $tempCredName = Generate-CredentialName -referenceObject $o -CredentialUsernamePropertyName "RoyalServerUsername"
                    $tempCred = Get-RoyalObject -Folder $docCreds -Name $tempCredName

                    

                     if($null -ne $tempCred)
                    {
                        if($tempCred.Password -ne $o.RoyalServerPassword)
                        {
                            $tempCred = $null
                        }
                    }

                    if($null -eq $tempCred)
                    {
                        # create a new cred and reference it
                        Create-ReferencedCredentials `
                            -CredName $tempCredName `
                            -CredentialUserName $o.RoyalServerUsername `
                            -CredentialPassword $o.RoyalServerPassword `
                            -ReferencingObject $o `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "RoyalServerCredentialMode" `
                            -CredentialNamePropertyName "RoyalServerCredentialName" `
                            -CredentialUsernamePropertyName "RoyalServerUsername" `
                            -CredentialPasswordPropertyName "RoyalServerPassword"
                    }
                    else
                    {
                        
                        # use the existing one
                        Update-Credential `
                            -Credential $o `
                            -ReferenceName $tempCredName `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "RoyalServerCredentialMode" `
                            -CredentialNamePropertyName "RoyalServerCredentialName" `
                            -CredentialUsernamePropertyName "RoyalServerUsername" `
                            -CredentialPasswordPropertyName "RoyalServerPassword"
                       
                    }
                }
            2
                {
                    # 2 = Use an existing credential
                    Update-ExistingCredential `
                        -referencedObject $o `
                        -CredentialMode 3 `
                        -CredentialModePropertyName "RoyalServerCredentialMode" `
                        -CredentialNamePropertyName "RoyalServerCredentialName" `
                        -CredentialUsernamePropertyName "RoyalServerUsername" `
                        -CredentialPasswordPropertyName "RoyalServerPassword"
                }
            3
                {
                    # 3 = Specify credential name 
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Specify Credential Nname '."
                }
        }
        #handle Secure Gateway Info
        switch ($o.SecureGatewayCredentialMode)
        {
            0 # Do not use any credentials
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)-SG) - Reason: 'Do Not Use Any Credentials'."
                }
            1 # Specify username and password
                {
                    $tempCredName = Generate-CredentialName -referenceObject $o -CredentialUsernamePropertyName "SecureGatewayUsername"
                    $tempCred = Get-RoyalObject -Folder $docCreds -Name $tempCredName
                    
                    if($null -eq $found)
                    {
                        # create a new cred and reference it
                        Create-ReferencedCredentials `
                            -CredName $tempCredName `
                            -CredentialUserName $o.SecureGatewayCredentialUserName `
                            -CredentialPassword $o.SecureGatewayCredentialPassword `
                            -ReferencingObject $o `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "SecureGatewayCredentialMode" `
                            -CredentialNamePropertyName "SecureGatewayCredentialName" `
                            -CredentialUsernamePropertyName "SecureGatewayUsername" `
                            -CredentialPasswordPropertyName "SecureGatewayPassword"
                    }
                    else
                    {
                        # use the existing one
                        Update-Credential `
                            -Credential $o `
                            -ReferenceName $tempCredName `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "SecureGatewayCredentialMode" `
                            -CredentialNamePropertyName "SecureGatewayCredentialName" `
                            -CredentialUsernamePropertyName "SecureGatewayUsername" `
                            -CredentialPasswordPropertyName "SecureGatewayPassword"
                    }
                }
            2 # Use an existing credential
                {
                    Update-ExistingCredential `
                        -referencedObject $o `
                        -CredentialMode 3 `
                        -CredentialModePropertyName "SecureGatewayCredentialMode" `
                        -CredentialNamePropertyName "SecureGatewayCredentialName" `
                        -CredentialUsernamePropertyName "SecureGatewayUsername" `
                        -CredentialPasswordPropertyName "SecureGatewayPassword"
                }
            3 # Specify credential name
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)-SG) - Reason: 'Specify Credential Name '."
                }
        }

        continue;
    }

    elseif($o.GetType().Name -eq "RoyalSecureGateway") # Secure Gateway Object
    {
        switch ($o.SecureGatewayCredentialMode)
        {
            0 # Do not use any credentials
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Do not use any credentials'."
                }
            1 # Specify username and password
                {
                    $tempCredName = Generate-CredentialName -referenceObject $o -CredentialUsernamePropertyName "SecureGatewayUsername"
                    $tempCred = Get-RoyalObject -Folder $docCreds -Name $tempCredName
                    if($null -ne $tempCred)
                    {
                        if($tempCred.Password -ne $o.SecureGatewayPassword)
                        {
                            $tempCredName = $null
                        }
                    }
                    if($null -eq $tempCred)
                    {
                        # create a new cred and reference it
                        Create-ReferencedCredentials `
                            -CredName $tempCredName `
                            -CredentialUserName $o.CredentialUserName `
                            -CredentialPassword $o.CredentialPassword `
                            -ReferencingObject $o `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "SecureGatewayCredentialMode" `
                            -CredentialNamePropertyName "SecureGatewayCredentialName" `
                            -CredentialUsernamePropertyName "SecureGatewayUsername" `
                            -CredentialPasswordPropertyName "SecureGatewayPassword"
                    }
                    else
                    {
                        
                            # use the existing one
                        Update-Credential `
                            -Credential $o `
                            -ReferenceName $tempCredName `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "SecureGatewayCredentialMode" `
                            -CredentialNamePropertyName "SecureGatewayCredentialName" `
                            -CredentialUsernamePropertyName "SecureGatewayUsername" `
                    }
                }
            2 # Use an existing credential
                {
                    Update-ExistingCredential `
                        -referencedObject $o `
                        -CredentialMode 3 `
                        -CredentialModePropertyName "SecureGatewayCredentialMode" `
                        -CredentialNamePropertyName "SecureGatewayCredentialName" `
                        -CredentialUsernamePropertyName "SecureGatewayUsername" `
                        -CredentialPasswordPropertyName "SecureGatewayPassword"
                }
            3 # Specify credential name
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Specify Credential Name '."
                }
        }

        continue;
    }
    elseif($o.GetType().Name -eq "RoyalKeySequenceTask") # Secure Gateway Object
    {
        switch ($o.CredentialMode)
        {
            0 # Do not use any credentials
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Do not use any credentials'."
                }
            1 # Specify username and password
                {
                    $tempCredName = Generate-CredentialName -referenceObject $o -CredentialUsernamePropertyName "CredentialUsername"
                    $tempCred = Get-RoyalObject -Folder $docCreds -Name $tempCredName
                    if($null -ne $tempCred)
                    {
                        if($tempCred.Password -ne $o.CredentialPassword)
                        {
                            $tempCredName = $null
                        }
                    }
                    
                    if($null -eq $tempCred)
                    {
                        # create a new cred and reference it
                        Create-ReferencedCredentials `
                            -CredName $tempCredName `
                            -CredentialUserName $o.CredentialUserName `
                            -CredentialPassword $o.CredentialPassword `
                            -ReferencingObject $o `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "CredentialMode" `
                            -CredentialNamePropertyName "CredentialName" `
                            -CredentialUsernamePropertyName "CredentialUsername" `
                            -CredentialPasswordPropertyName "CredentialPassword"
                    }
                    else
                    {
                        # use the existing one
                        Update-Credential `
                            -Credential $o `
                            -ReferenceName $tempCredName `
                            -CredentialMode 3 `
                            -CredentialModePropertyName "CredentialMode" `
                            -CredentialNamePropertyName "CredentialName" `
                            -CredentialUsernamePropertyName "CredentialUsername" `
                            -CredentialPasswordPropertyName "CredentialPassword"    
                    }
                }
            2 # Use an existing credential
                {
                    Update-ExistingCredential `
                        -referencedObject $o `
                        -CredentialMode 3 `
                        -CredentialModePropertyName "CredentialMode" `
                        -CredentialNamePropertyName "CredentialName" `
                        -CredentialUsernamePropertyName "CredentialUsername" `
                        -CredentialPasswordPropertyName "CredentialPassword"
                }
            3 # Specify credential name
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Specify credential name'."
                }
        }

        continue;
    }
    else #standard object
    {
        switch ($o.CredentialMode)
        {
            
            0 # Do not use any credential
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Do not use any credential'."
                }
            1 # Use credentials from the parent folder
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Use credentials from the parent folder'."
                }
            2 # Specify username and password
                {
                    $tempCredName = Generate-CredentialName -referenceObject $o -CredentialUsernamePropertyName "CredentialUsername"
                    
                    $tempCred = Get-RoyalObject -Folder $docCreds -Name $tempCredName
                    if($null -ne $tempCred)
                    {
                        if($tempCred.Password -ne $o.CredentialPassword)
                        {
                            $tempCredName = $null
                        }
                    }
                    
                    if($null -eq $tempCred)
                    {
                        # create a new cred and reference it
                        Create-ReferencedCredentials `
                            -CredName $tempCredName `
                            -CredentialUserName $o.CredentialUserName `
                            -CredentialPassword $o.CredentialPassword `
                            -ReferencingObject $o `
                            -CredentialMode 4 `
                            -CredentialModePropertyName "CredentialMode" `
                            -CredentialNamePropertyName "CredentialName" `
                            -CredentialUsernamePropertyName "CredentialUsername" `
                            -CredentialPasswordPropertyName "CredentialPassword"
                    }
                    else
                    {
                        # use the existing one
                        Update-Credential `
                        -Credential $o `
                        -ReferenceName $tempCredName `
                        -CredentialMode 4 `
                        -CredentialModePropertyName "CredentialMode" `
                        -CredentialNamePropertyName "CredentialName" `
                        -CredentialUsernamePropertyName "CredentialUsername" `
                        -CredentialPasswordPropertyName "CredentialPassword"
                    }
                }
            3 # Use an existing credential
                {
                    Update-ExistingCredential `
                        -referencedObject $o `
                        -CredentialMode 4 `
                        -CredentialModePropertyName "CredentialMode" `
                        -CredentialNamePropertyName "CredentialName" `
                        -CredentialUsernamePropertyName "CredentialUsername" `
                        -CredentialPasswordPropertyName "CredentialPassword"                            
                }
            4 # Specify a credential name
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Specify a Credential Name'."
                }
            5
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'Credential from Context'."
                }
            default
                {
                    Write-Log "    -> Skipped $($o.Name) ($($o.GetType().Name)) - Reason: 'No Property CredentialMode.'"
                }
        }

        continue;
    }
}
Write-Log "Migrating all other Object Types... done." -Level INF


# output cred files
Write-Log "Saving $credsFileName" -Level INF
Out-RoyalDocument -Document $docCreds -FileName $credsFileName

Write-Log "Saving $credsEmptyFileName" -Level INF
Out-RoyalDocument -Document $docCredsEmpty -FileName $credsEmptyFileName

# output the changed document to another file
Write-Log "Saving $docModifiedFileName" -Level INF
Out-RoyalDocument -Document $doc -FileName $docModifiedFileName

Close-RoyalDocument -Document $doc
Close-RoyalDocument -Document $docCreds
Close-RoyalDocument -Document $docCredsEmpty

# Take out the Trash in the new file
$splittedDoc = Open-RoyalDocumentFile -fileName $docModifiedFileName
$prevDeletedObjectRetention = $splittedDoc.DeletedObjectRetention
$splittedDoc.DeletedObjectRetention = 0
Write-Log "Cleaning up Trashcan..." -Level INF
$trash = $splittedDoc.Trashcan
$trash.TakeOutTheTrash()
$splittedDoc.DeletedObjectRetention = $prevDeletedObjectRetention
Out-RoyalDocument -Document $splittedDoc -FileName $docModifiedFileName
Close-RoyalDocument -Document $splittedDoc
Write-Log "Cleaning up Trashcan... done" -Level INF

    
Write-Log "Splitting Credentials done." -Level INF

#endregion Core Logic
#------------------------------------------------------------