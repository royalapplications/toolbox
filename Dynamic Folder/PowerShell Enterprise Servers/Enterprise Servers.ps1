#need to use the module active directory to get data
#the domain of the test environment is Company.pri
Import-Module ActiveDirectory
#using an arrayList instead of a standard array for speed
#standard array is copied to a new object each time an item is added
#on small amounts of items, this is not an issue but large
#amounts of items will result in slow execution
[System.Collections.ArrayList]$array = @()
#any other OU can be placed instead of Company.pri if needed
#searching the subtree allows for any comptuers located in the OU Enterprise Servers
#to be included in the list - if this is not needed then searchscope can be changed
#canonical name is used to create the folder path for the computer to sit in in the dynamic folder
foreach ($computer in Get-ADComputer -SearchBase "ou=Enterprise Servers,dc=company,dc=pri" -Filter * -SearchScope subtree -Properties canonicalname)
{
	$array.add((
			New-Object -TypeName System.Management.Automation.PSObject -Property @{
				"Type" = "RemoteDesktopConnection";
				"Name" = $computer.name;
				"ComputerName" = $computer.name;
				"credentialName" = "mikes";
				"Path" = $computer.canonicalname.replace("/$($computer.name)", "")
			}
		)) | Out-Null #if you don't use out-null with an arraylist it will give you invalid output and cause the script to fail
}
#sorting the array is optinal - this is done only if you want to make the OU structure mirror that of your AD
$array = $array | Sort-Object -Property path
$hash = @{ }
#This creates the hash table correctly so the resulting json file is compliant with RoyalJSON
$hash.add("Objects", $array)
#no need to use write-host here - writing to the stream works just as well (tested with PS 5.1)
$hash | ConvertTo-Json -depth 100