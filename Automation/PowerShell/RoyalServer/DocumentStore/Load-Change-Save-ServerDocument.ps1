<#
    The example code below demonstrates how to
    - 1. Load a document hosted by Royal Server
    - 2. Modify that document in memory
    - 3. Save it back to Royal Server

    23-07-2025  Creation
#>
Import-Module -Name RoyalDocument.PowerShell
Import-Module RoyalDocument.PowerShell

###############################################################################
# variables - adapt to your needs
$royalServerHost = "127.0.0.1"
$adminUsername = "user"
$adminPassword = "pwd"


###############################################################################
# 1. Load a document hosted by Royal Server
###############################################################################
$store = New-RoyalStore -UserName "ScriptUser"
# the following tempDoc is just in memory to give the RoyalManagementEndpoint space to live in
$tempDoc = New-RoyalDocument -Store $store -FileName "C:\Temp\Test.rtsz" -Name "documentname"
$endpoint = New-RoyalObject -folder $tempDoc -Type RoyalManagementEndpoint -Name "Royal Server Object Test" -Description "description"

# https://docs.royalapps.com/r2021/scripting/objects/gateways/royalmanagementendpoint.html
Set-RoyalObjectValue -Object $endpoint -Property "RoyalServerHost" -Value $royalServerHost
Set-RoyalObjectValue -Object $endpoint -Property "RoyalServerCredentialMode" -Value 1 #username/pwd
Set-RoyalObjectValue -Object $endpoint -Property "RoyalServerUsername" -Value $adminUsername
Set-RoyalObjectValue -Object $endpoint -Property "RoyalServerPassword" -Value $adminPassword

 
###############################################################################
# 2. Modify that document in memory
############################################################################### 
# This gets a list of all available Royal Server documents
# The returned data contains metadata of the documents, not the content itself
# possible properties to filter are DocumentId, DocumentName, DocumentDescription etc
# It also contains "PermissionToModify" to indicate, if you can save back any changes
$rsdocs = Get-RoyalServerDocument -RoyalServer $endpoint -IgnoreCertificateWarning
$rsDocEntry = $rsdocs[0] # for demonstration purposes take the first document

# if needed, provide -Password and -LockdownPassword as well as SecureStrings 
# for opening the document
$rsdoc = Open-RoyalServerDocument -RoyalServer $endpoint -RoyalServerDocument $rsdocEntry -IgnoreCertificateWarning

# add a new RDP connection in memory
$rds = New-RoyalObject -Folder $rsdoc -Type RoyalRDSConnection -Name "test-connection by powershell"
Set-RoyalObjectValue -Object $RDS -Property URI -Value srv01.demo.local


###############################################################################
# 3. Save it back to Royal Server
###############################################################################
Out-RoyalServerDocument -RoyalServer $endpoint -RoyalServerDocument $rsdocEntry -Document $rsdoc
