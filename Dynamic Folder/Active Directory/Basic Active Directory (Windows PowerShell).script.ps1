Import-Module ActiveDirectory
[System.Collections.ArrayList]$array = @()
foreach ($computer in Get-ADComputer -SearchBase "$CustomProperty.SearchBase$" -Filter '$CustomProperty.Filter$' -SearchScope $CustomProperty.SearchScope$ -Properties canonicalname)
{
	$array.add((
			New-Object -TypeName System.Management.Automation.PSObject -Property @{
				"Type" = "$CustomProperty.ConnectionType$";
				"Name" = $computer.name;
				"ComputerName" = $computer.name;
				"credentialName" = "$CustomProperty.CredentialName$";
				"Path" = $computer.canonicalname.replace("/$($computer.name)", "")
			}
		)) | Out-Null
}
$array = $array | Sort-Object -Property path
$hash = @{ }
$hash.add("Objects", $array)

$hash | ConvertTo-Json