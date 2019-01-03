$VMMServer = 'VMM01.powershell.no'
$VMMCredentialPath = "$env:USERPROFILE\VMM.cred.xml"
$RDPCredentialName = 'DOMAIN\username'
$SSHCredentialName = 'username'

function Get-ServerFromSCVMM {
    <#
       .SYNOPSIS
       Get-ServerFromSCVMM is a command to retrieve server information from System Center Virtual Machine Manager.
       .DESCRIPTION
       Get-ServerFromSCVMM is a command to retrieve server information from System Center Virtual Machine Manager.

            Required version: Windows PowerShell 3.0 or later 
            Required modules: VirtualMachineManager
            Required privileges: Read-permission in SC VMM

       .EXAMPLE
       Get-ServerFromSCVMM -VMMServer SRV01 -Credential (Get-Credential)
       .EXAMPLE
       Export data to Excel (requires the ImportExcel module)
       $XlsxPath = 'C:\temp\Servers_VMM_InventoryReport.xlsx'
       Get-ServerFromSCVMM -VMMServer SRV01 -Credential (Get-Credential) | 
       Export-Excel -Path $XlsxPath -WorkSheetname Servers -AutoSize -TableName Servers -TableStyle Light1
   #>
   [CmdletBinding()]
    Param(
        [PSCredential]$Credential = (Get-Credential),
        [string]$VMMServer = 'SRV01'
    )


    $VMMData = @()

    try {

        Write-Verbose "Connecting to VMM Server $VMMServer"

        $VMMPSSession = New-PSSession -ComputerName $VMMServer -Credential $Credential -ErrorAction Stop

        Write-Verbose "Getting VM hosts"

        $VMHosts = Invoke-Command -Session $VMMPSSession -ScriptBlock {

            $null = Get-SCVMMServer -ComputerName $using:VMMServer
            Get-SCVMHost | Select-Object @{n='Name';e={$_.ComputerName}}, @{n='IsVirtualMachine';e={$false}}, LogicalCPUCount, PhysicalCPUCount, @{Name = "MemoryInGB"; Expression = {"{0:N2}" -f ($_.TotalMemory / 1gb)}}, @{Name = "TotalStorageCapacityInGB"; Expression = {"{0:N2}" -f ($_.LocalStorageTotalCapacity / 1gb)}}, Operatingsystem
        

        } -ErrorAction Stop | Select-Object Name,IsVirtualMachine,LogicalCPUCount,PhysicalCPUCount,MemoryInGB,TotalStorageCapacityInGB,OperatingSystem,Description

        $VMMData += $VMHosts

        Write-Verbose "Found $($VMHosts.Count) VM hosts in VMM"

        Write-Verbose  "Getting VMs"

        $VMs = Invoke-Command -Session $VMMPSSession -ScriptBlock {

            Get-SCVirtualMachine | 
                Where-Object ReplicationMode -ne 'Recovery' | 
                Where-Object {$PSItem.OperatingSystem.Name -notlike "*Windows XP*" -and $PSItem.OperatingSystem.Name -notlike "*Windows 7*" -and $PSItem.OperatingSystem.Name -notlike "*Windows 10*" -and $PSItem.OperatingSystem.Name -ne 'Unknown'} | 
                Select-Object Name, @{n='IsVirtualMachine';e={$true}}, @{n = 'LogicalCPUCount'; e = {$PSItem.CPUCount}}, PhysicalCPUCount, @{Name = "MemoryInGB"; Expression = {"{0:N2}" -f ($_.Memory / 1kb)}}, @{Name = "TotalStorageCapacityInGB"; Expression = {"{0:N2}" -f ($_.TotalSize / 1gb)}}, Operatingsystem,Description
      

        } -ErrorAction Stop | Select-Object Name,IsVirtualMachine,LogicalCPUCount,PhysicalCPUCount,MemoryInGB,TotalStorageCapacityInGB,OperatingSystem,Description

        $VMMData += $VMs

        Write-Verbose "Found $($VMs.Count) VMs in VMM" 

    }

    catch {

        Write-Error "An error occured during VMM operations: $($_.Exception.Message)"

    }    

    if ($VMMPSSession) {

        $VMMPSSession | Remove-PSSession

    }

    $VMMData

}

if (Test-Path -Path $VMMCredentialPath) {

    $VMMCredential = Import-Clixml -Path $VMMCredentialPath

} else {

    $VMMCredential = Get-Credential -Message 'Specify VMM credentials'
    $VMMCredential | Export-Clixml -Path $VMMCredentialPath

}

[System.Collections.ArrayList]$Servers = @()

Get-ServerFromSCVMM -ComputerName $VMMServer -Credential $VMMCredential | ForEach-Object {

    $Server = $PSItem

    if ($Server.Description) {

        $Description = ($Server.OperatingSystem.Name + ' (' + $Server.Description + ')')

    } else {

        $Description = $Server.OperatingSystem

    }

    switch -Wildcard ($PSItem.OperatingSystem)
    {
        "*Linux*" {
        
            $null = $Servers.Add([PSCustomObject]@{
            Name = $Server.Name
            Type = 'TerminalConnection'
            TerminalConnectionType = 'SSH'
            ComputerName = $Server.Name
            CredentialName = $SSHCredentialName
            Path = 'Linux'
            Description = $Description
        })
        }
    
        "*Windows*" {
        
            $null = $Servers.Add([PSCustomObject]@{
            Name = $Server.Name
            Type = 'RemoteDesktopConnection'
            ComputerName = $Server.Name
            CredentialName = $RDPCredentialName
            Path = 'Windows'
            Description = $Description
        })
        
        }
    
        Default {
        
            $null = $Servers.Add([PSCustomObject]@{
            Name = $Server.Name
            Type = 'RemoteDesktopConnection'
            ComputerName = $Server.Name
            Path = 'Other'
            Description = $Description
        })
        
        }
    
    }

} 

$RoyalTSObjects = @{}
$null = $RoyalTSObjects.Add('Objects',$Servers)


$RoyalTSObjects | ConvertTo-Json