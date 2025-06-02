$objCred=new-object System.Management.automation.pscredential -ArgumentList '$EffectiveUsername$',(Convertto-securestring '$EffectivePassword$' -AsPlainText -Force)

$vcServers = '$CustomProperty.ServerURL$'

$vcServers=$vcServers.split(',')


foreach ($vcenter in $vcServers) {
    connect-viserver -credential $objCred $vcenter > $null
}

#write-host 'Loading Virtual Machines...'
$vmList=get-vm | where { $_.PowerState -eq 'PoweredOn' }

$mySystems=$vmList | select Name,Guest,GuestId,@{n='IPAddress'; e={(get-vmguest -vm $_).Nics.IPAddress }},@{n='Datacenter'; e={($_ | get-datacenter).name } }, @{n='Cluster'; e= {($_ | get-cluster).name} }
$ServerList = new-object System.Collections.ArrayList

$ipv4Match='^(?:(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)\.){3}(?:0?0?\d|0?[1-9]\d|1\d\d|2[0-5][0-5]|2[0-4]\d)$'


foreach ($vm in $mySystems) {
    $vmName=$vm.Name
    $folderName="$($vm.datacenter)/$($vm.cluster)"
    if ($vm.guest.extensiondata.guestfamily -match 'windows') { $vmType='RemoteDesktopConnection'}
    if ($vm.guest.extensiondata.guestfamily -match 'Linux') {$vmType='SSH'}
    
    if ([string]::IsNullOrEmpty($vmType) -eq $true) {
        if ($vm.guestid -match 'windows') { 
            $vmType='RemoteDesktopConnection'
        } else {
            $vmType='SSH'
        }
    }

    $IPAddress=($vm.guest.extensiondata.net.ipaddress -match  $ipv4Match)[0]
    
	if ($IPAddress -eq $true) {
        $IPAddress=$vm.guest.extensiondata.net.ipaddress
    }

    if ($vm.guest.extensiondata.guestfamily -match 'windows') {
     $tmpObj=[pscustomobject]@{
        Name = $vmName
        Path = $folderName
        ComputerName = $IPAddress
        Type = $vmType
		CredentialName = '$CustomProperty.WindowsCredential$'
     }
     
    }

    if ($vm.guest.extensiondata.guestfamily -match 'Linux') {
     $tmpObj=[pscustomobject]@{
            Name = $vmName
            Path = $folderName
            ComputerName = $IPAddress
            TerminalconnectionType = $vmType
            Type='TerminalConnection'
			CredentialName = '$CustomProperty.LinuxCredential$'
     }        
    }

    [void] $serverList.add($tmpObj)

}

$objRoyalTS=@{}
[void] $objRoyalTS.add('Objects',$serverList)

#$objRoyalTS | ConvertTo-Json | out-file 'royalts.json'


$objRoyalTS | ConvertTo-Json