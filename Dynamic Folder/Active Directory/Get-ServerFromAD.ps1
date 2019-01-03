$ADDomainController = 'powershell.no'
$InactiveComputerObjectThresholdInDays = '14'
$RDPCredentialName = 'DOMAIN\username'
$ADCredentialPath = "$env:USERPROFILE\AD.cred.xml"

function Get-ServerFromAD {
    <#
      .SYNOPSIS
      Get-ServerFromAD is a command to retrieve server information from Active Directory.
      .DESCRIPTION
      Get-ServerFromAD is a command to retrieve server information from Active Directory.

      You need to install Remote Server Administration Tools (RSAT) in order to leverage the Active Directory module for PowerShell from a workstation. Starting with Windows 10 October 2018 Update, RSAT is included as a set of "Features on Demand" in Windows 10 itself. From PowerShell, it can be installed using this command:
      Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0


           Required version: Windows PowerShell 3.0 or later 
           Required modules: ActiveDirectory
           Required privileges: Read-permission in AD

      .EXAMPLE
      Get-ServerFromAD
      .EXAMPLE
      Export data to Excel (requires the ImportExcel module)
      $XlsxPath = 'C:\temp\Servers_AD_InventoryReport.xlsx'
      Get-ServerFromAD | 
      Export-Excel -Path $XlsxPath -WorkSheetname Servers -AutoSize -TableName Servers -TableStyle Light1
  #>

    [CmdletBinding()]
    Param(
        [string]$InactiveComputerObjectThresholdInDays = 30,
        [string]$RootOUPath,
        [string]$ADDomainController,
        [pscredential]$ADCredential
    )

    try {
        
        Import-Module -Name ActiveDirectory -ErrorAction Stop -WarningAction SilentlyContinue
        
    } catch {
        
        Write-Error -Message 'Prerequisites missing (ActiveDirectory module not installed)'
        break
        
    }

    $Parameters = @{}

    $null = $Parameters.Add('LDAPFilter', "(&(objectCategory=computer)(operatingSystem=Windows Server*)(!serviceprincipalname=*MSClusterVirtualServer*))")

    $ADProperty = 'name', 'operatingSystem', 'lastlogondate', 'description', 'DistinguishedName', 'CanonicalName'
    $null = $Parameters.Add('Properties', $ADProperty)

    if ($ADCredential) {

        $null = $Parameters.Add('Credential', $ADCredential)

    }

    if ($RootOUPath) {

        $null = $Parameters.Add('SearchBase', $RootOUPath)

    }

    if ($ADDomainController) {

        $null = $Parameters.Add('Server', $ADDomainController)

    }

    Get-ADComputer @Parameters |
        Where-Object lastlogondate -gt (Get-Date).AddDays( - $InactiveComputerObjectThresholdInDays) |  
        Select-Object -Property $ADProperty |
        Sort-Object -Property name
        
}

$ADCredentialPath = "$env:USERPROFILE\AD.cred.xml"

if (Test-Path -Path $ADCredentialPath) {

    $ADCredential = Import-Clixml -Path $ADCredentialPath

} else {

    $ADCredential = Get-Credential -Message 'Specify AD credentials'
    $ADCredential | Export-Clixml -Path $ADCredentialPath

}

[System.Collections.ArrayList]$Servers = @()

Get-ServerFromAD -InactiveComputerObjectThresholdInDays $InactiveComputerObjectThresholdInDays -ADDomainController $ADDomainController -ADCredential $ADCredential | ForEach-Object {

    $null = $Servers.Add([PSCustomObject]@{
        Name = $PSItem.Name
        Type = 'RemoteDesktopConnection'
        ComputerName = $PSItem.Name
        #CredentialName = 'DOMAIN\username'
        Path = $PSItem.CanonicalName.Replace("/$($PSItem.Name)",'')
    })

} 

$RoyalTSObjects = @{}
$null = $RoyalTSObjects.Add('Objects',$Servers)


$RoyalTSObjects | ConvertTo-Json