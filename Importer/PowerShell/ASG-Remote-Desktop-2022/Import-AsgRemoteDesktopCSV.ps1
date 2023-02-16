<#
.SYNOPSIS
  Imports a CSV export from for ASG Remote Desktop 2022
.DESCRIPTION
  This script imports all connections from a CSV export done with ASG Remote Desktop 2022
.INPUTS
  A CSV file specified in the variable $csvFileName 
.OUTPUTS
  Royal Document saved to $fileName
.NOTES
  Name:           Import-AsgRemoteDesktopCSV
  Version:        0.1.0
  Author:         Michael Seirer
  Copyright:      (C) 2023 RoyalApps GmbH
  Creation Date:  February 6, 2023
  Modified Date:  February 6, 2023
  Support:        For support please check out the "Support" section in the README file here:
                  https://github.com/royalapplications/toolbox
  Prerequisites:  RoyalDocument.PowerShell is installed on the system
.LINK
  https://github.com/royalapplications/toolbox/tree/master/Importer/PowerShell/ASG-Remote-Desktop-CSV/Import-AsgRemoteDesktopCSV.ps1
#>
Import-Module -Name RoyalDocument.PowerShell

# adapt variables to your liking
$fileName = "outputcsv.rtsz" #relative to the current powershell workign directory
$csvFileName = "asg_connections.csv"
$folderSplitter = "\\"
$delimiter = ";" 


# magic happens here
$store = New-RoyalStore -UserName "PowerShellUser"
$doc = New-RoyalDocument -Store $store -Name "Powershell import from ASG Remote Desktop CSV export" -FileName $fileName

function CreateRoyalFolderHierarchy()
{
    param(
    [string]$folderStructure,
    [string]$splitter,
    $Folder
        )

    if(!$folderStructure) { return $doc }

    $currentFolder = $Folder

    $folderStructure -split $splitter | %{
        $folder = $_
        $existingFolder = Get-RoyalObject -Folder $currentFolder -Name $folder -Type RoyalFolder
        if($existingFolder)
        {
            Write-Verbose "Folder $folder already exists - using it"
            $currentFolder = $existingFolder
        }
        else
        {
            Write-Verbose "Folder $folder does not exist - creating it"
            $newFolder= New-RoyalObject -Folder $currentFolder -Name $folder -Type RoyalFolder
            $currentFolder  = $newFolder
        }
    }

    # handle objects in root
    if(!$currentFolder) { return $doc }
    else { return $currentFolder }
}

Import-CSV -Path $csvFileName -Delimiter $delimiter| %{
       
    $server = $_
    Write-Host "Importing $($server.ConnectionName) into Folder $($lastFolder.Name) into $($server.FolderName)"
    

    # the folder hierarchy is in the csv field FolderName
    $lastFolder = CreateRoyalFolderHierarchy -folderStructure $server.FolderName -Splitter $folderSplitter -Folder $doc

    # determine connection type to import
    if ($server.ConnectionProtocol -eq "RDP") {
        $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalRDSConnection -Name $server.ConnectionName 
        $newconnection.RDPPort = $server.ConnectionPort
        $newConnection.PhysicalAddress = $server.ConnectionMACAddress
    }
    elseif ($server.ConnectionProtocol -eq "VNC") {
        $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalVNCConnection -Name $server.ConnectionName 
        $newConnection.Port = $server.ConnectionPort
        $newConnection.PhysicalAddress = $server.ConnectionMACAddress
    }
    elseif ($server.ConnectionProtocol -eq "Telnet") {
        $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalSSHConnection -Name $server.ConnectionName
        $newConnection.IsTelnetConnection = $true    
        $newConnection.Port = $server.ConnectionPort
        $newConnection.PhysicalAddress = $server.ConnectionMACAddress
    }
    elseif ($server.ConnectionProtocol -eq "SSH") {
        $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalSSHConnection -Name $server.ConnectionName 
        $newConnection.Port = $server.ConnectionPort
        $newConnection.PhysicalAddress = $server.ConnectionMACAddress
    }
    elseif ($server.ConnectionProtocol -eq "HTTP") { 
        $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalWebConnection -Name $server.ConnectionName 
    }
    elseif ($server.ConnectionProtocol -eq "ExtApp") { 
        $newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalAppConnection -Name $server.ConnectionName 
    }
    else
    {
        Write-Warning "ConnectionProtocol $($server.ConnectionProtocol) unknown - skipping $($server.ConnectionName)"
        return
    }

    # standard properties
    $newConnection.URI = $server.ConnectionIpAddress
    if ($server.ConnectionProtocol -eq "HTTP") { $newConnection.URI = $server.ConnectionUrl }
    $newConnection.Name = $server.ConnectionName
    $newConnection.Description = $server.Description    
    $newConnection.CustomField1 = $server.ConnectionCustom1
    $newConnection.CustomField2 = $server.ConnectionCustom2
    $newConnection.CustomField3 = $server.ConnectionCustom3

}

Out-RoyalDocument -Document $doc -FileName $fileName