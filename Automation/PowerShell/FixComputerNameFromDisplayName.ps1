##
# Description: This simple script updates all URIs (hostnames) to match the current display name.
# In the past we had a customer accidentally messing up the hostnames when using the bulk-edit
# functionality, resulting that no connections were working anymore. Fixing this in a manual way
# might be a lot of work in larger documents. PowerShell script to the rescue.
##
# To see available object types and their names please take a look in the documentation at
# "References - Object Properties" (see navigation panel) on following site:
#  https://content.royalapplications.com/Help/RoyalTS/V5/index.html?scripting_gettingstarted.htm
##

# variables to configure.
$docPath = "Test.rtsz" # exact path to the document file
$types = @( "RoyalRDSConnection", "RoyalSSHConnection" ) # which object types should be changed.
$domain = "domain.tld" # which domain name should be appended to have a FQDN in the end

# magic happens here.
Import-Module Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Royal TS V5\RoyalDocument.PowerShell.dll'

$store = New-RoyalStore -UserName ($env:USERDOMAIN + '\' + $env:USERNAME)
$doc = Open-RoyalDocument -FileName $docPath -Store $store

foreach($type in $types) {
    Get-RoyalObject -Folder $doc -Type $type | ForEach-Object {
        $uri = $_.Name + $domain
        Set-RoyalObjectValue -Object $_ -Property URI -Value $uri
    }
}

Out-RoyalDocument -Document $doc
