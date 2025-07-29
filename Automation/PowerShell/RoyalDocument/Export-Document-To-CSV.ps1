<#
    Changing document and lockdown password via code for a Royal Document

    Steps: 
        1. Opens a local document
        2. exports all objects of the specified types in a .csv file

    2025-07-29  Creation
#>
Import-Module RoyalDocument.PowerShell


###############################################################################
# Helper function that builds the full path of an object
function Get-ParentFolderPath($params)
{
    $o = Get-RoyalObject -Folder $params[0] -Id $params[1].ParentId

    if($null -ne $o) {
        if($null -ne $o.ParentId) {
            $( $(Get-ParentFolderPath $params[0], $o) + "/" + $o.Name)
        }
        else {
            $o.Name
        }
    }
}

###############################################################################
# variables, set accordingly
$fileName = "export-csv.rtsz"
$csvFileName = "exported-csv.csv"

#supported Export Types
$exportedObjectTypes = @(
    "RoyalFolder",
    "RoyalDynamicFolder",        
    "RoyalCredential",
    "RoyalDynamicCredential",
    "RoyalToDo",
    "RoyalRDSConnection",
    "RoyalVNCConnection", 
    "RoyalSSHConnection",
    "RoyalFileTransferConnection",   
    "RoyalWebConnection",
    "RoyalTeamViewerConnection",     
    "RoyalAppConnection",
    "RoyalPerformanceConnection",    
    "RoyalPowerShellConnection",
    "RoyalWindowsEventsConnection",
    "RoyalWindowsProcessesConnection",
    "RoyalWindowsServicesConnection",
    "RoyalTerminalServicesConnection",
    "RoyalHyperVConnection",
    "RoyalVMwareConnection",
    "RoyalManagementEndpoint",
    "RoyalSecureGateway",
    "RoyalRDSGateway",
    "RoyalCommandTask",
    "RoyalKeySequenceTask",
    "RoyalApplicationSetting"
) 

# Open the RoyalTS document
$store = New-RoyalStore -UserName "ScriptUser"
$doc = Open-RoyalDocument -Store $store -FileName $fileName

$allObjects = @() 

if ($null -ne $doc) {

    foreach ($objectType in $exportedObjectTypes)
    {
        # iterate over all entries in the document and create an object using the following structure
        # Type|ID|Name|IP|Description|Username|Password|Folder
        foreach ($entry in Get-RoyalObject -Folder $doc -Type $objectType)
        {
            Write-Host "Working on $($entry)"
            $typeName = $entry.GetType().Name.Split(".")[-1] #get the name after the last "."
            $psEntry = [PSCustomObject]@{
                Type     = $typeName 
                ID       = "$($entry.ID)"
                Name     = "$($entry.Name)"
                Description = "$($entry.Description)"
                Username    = "$($entry.EffectiveUsername)"
                #Warning: Exporting passwords in plaintext (e.g., to CSV) can lead to credential leaks. 
                #Password    = "$($entry.EffectivePassword)"
                Folder      = Get-ParentFolderPath $doc, $entry  # the Folder column is containing the full hierarchy 
            }

            $allObjects += $psEntry
        }
    }  

    # export as CSV
    Write-Host "Exporting $($allObjects.Length) objects"
    $allObjects | Export-Csv -Path $csvFileName -NoTypeInformation


    Write-Host "CSV export done"

} else {
    Write-Host "Failed to load the RoyalTS document."
}