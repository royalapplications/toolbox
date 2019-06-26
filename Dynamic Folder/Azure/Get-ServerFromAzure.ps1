$AzCredentialPath = "$env:USERPROFILE\Azure.cred.xml"
$AzSubscriptionId = 'xxxx-xxxx-xxxx-xxxx'

$RDPCredentialName = 'CONTOSO\adminuser'
$SSHCredentialName = 'SSHUser'

if (Get-Module -Name Az.Compute -ListAvailable) {


    function Get-ServerFromAzure {
        <#
      .SYNOPSIS
      Get-ServerFromAzure is a command to retrieve server information from Microsoft Azure.
      .DESCRIPTION
      Get-ServerFromAzure is a command to retrieve server information from Microsoft Azure.

           Required version: Windows PowerShell 3.0 or later
           Required modules: Az
           Required privileges: Read-permission in Azure

      .EXAMPLE
      Get-ServerFromAzure -SubscriptionId 'c0fda861-649f-49ee-9ede-fa1908101500' -Credential (Get-Credential)

  #>

        [CmdletBinding()]
        Param(
            [PSCredential]$Credential = (Get-Credential),
            [string]$SubscriptionId
        )

        try {

            Import-Module -Name Az.Compute -ErrorAction Stop -Verbose:$false

        }

        catch {

            Write-Error -Message 'Prerequisites missing (Az PowerShell module not installed)'
            break

        }

        try {

            $null = Get-AzSubscription -ErrorAction Stop

        }

        catch {

            try {
                $null = Connect-AzAccount -Credential $Credential -ErrorAction Stop

            }

            catch {

                Write-Error -Message 'Azure Resource Manager authentication failed'
                break

            }

        }

        if (-not ((Get-AzContext).Subscription.Id -eq $SubscriptionId)) {

            $null = Set-AzContext -SubscriptionId $SubscriptionId

        }

        $AllNICs = Get-AzNetworkInterface

        Get-AzVM | Select-Object  Name, @{n = 'IpAddress'; e = {($AllNICs | Where-Object id -eq $_.NetworkProfile.NetworkInterfaces[0].Id).IpConfigurations[0].PrivateIpAddress}}, @{Name = 'OSType'; e = {if ($_.OSProfile.WindowsConfiguration) {'Windows'} else {'Linux'}}}

    }


    if (Test-Path -Path $AzCredentialPath) {

        $ADCredential = Import-Clixml -Path $AzCredentialPath

    } else {

        $AzCredential = Get-Credential -Message 'Specify Azure credentials'
        $AzCredential | Export-Clixml -Path $AzCredentialPath

    }

    [System.Collections.ArrayList]$Servers = @()

    Get-ServerFromAzure -SubscriptionId $AzSubscriptionId -Credential $AzCredential | Sort-Object -Property Name | ForEach-Object {

        $Server = $PSItem

        switch -Wildcard ($PSItem.OSType) {
            "*Linux*" {

                $null = $Servers.Add([PSCustomObject]@{
                        Name                   = $Server.Name
                        Type                   = 'TerminalConnection'
                        TerminalConnectionType = 'SSH'
                        ComputerName           = $Server.IpAddress
                        CredentialName         = $SSHCredentialName
                        Path                   = 'Linux'
                        #Description = $Description
                    })
            }

            "*Windows*" {

                $null = $Servers.Add([PSCustomObject]@{
                        Name           = $Server.Name
                        Type           = 'RemoteDesktopConnection'
                        ComputerName   = $Server.IpAddress
                        CredentialName = $RDPCredentialName
                        Path           = 'Windows'
                        #Description = $Description
                    })

            }

            Default {

                $null = $Servers.Add([PSCustomObject]@{
                        Name         = $Server.Name
                        Type         = 'RemoteDesktopConnection'
                        ComputerName = $Server.IpAddress
                        Path         = 'Other'
                        #Description = $Description
                    })

            }

        }

    }

    $RoyalTSObjects = @{}
    $null = $RoyalTSObjects.Add('Objects', $Servers)


    $RoyalTSObjects | ConvertTo-Json


}