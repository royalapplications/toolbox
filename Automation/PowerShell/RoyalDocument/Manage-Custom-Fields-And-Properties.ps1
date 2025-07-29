<#
    Manage Custom Fields And Properties in a Royal Document

    Steps: 
        1. Opens a local Royal Document
        2. Change the Custom Field1, CustomField11 (encrypted) 
        3. Wotk with Custom Properties
        4. Save the document

    2025-07-29  Creation
#>
Import-Module RoyalDocument.PowerShell
  
###############################################################################
# variables - adapt to your needs
$fileName = "cust-field-document.rtsz"
$connectionId = "3f012ab2-453c-4c83-9d31-d5d563be95bd"
$customPropertyId = "8671bd02-2b85-4422-8fba-a35fdf5fced9"


###############################################################################
# 1. Load a document hosted by Royal Server
###############################################################################
$store = New-RoyalStore -UserName "ScriptUser"
$doc = Open-RoyalDocument -Store $store -FileName $fileName
if ($doc -eq $null) {
    Write-host "Document could not be found."
    exit 1
}

# Get some object from the file
$connection = Get-RoyalObject -Folder $doc -Id $connectionId

###############################################################################
# 2. Change Custom Fields
###############################################################################
$connection.CustomField1 = "new value"
$connection.CustomField11 = "new encrypted value" #Custom Fields from 11 to 20 will be stored encrypted


###############################################################################
# 3. Work with Custom Properties
###############################################################################
# get a specific Custom Property by ID
$rocp = Get-RoyalObjectCustomProperty -Object $connection -Id $customPropertyId
# Setting a Custom Properties value via the CommandLet
Set-RoyalObjectCustomProperty -Object $connection -Id $customPropertyId -Label "new Text Title" -Value "new Text Value"


# Iterating over all Custom Properties
$cp = Get-RoyalObjectCustomProperty -Object $connection #returns all Custom Properties
foreach($c in $cp)
{
    Write-Host "$($c.Id) - $($c.Label) - $($c.Value)"

    # Alternatively, set the Custom Property directly
    #$c.Label = "new label"
    #$c.Value = "new value"
}


###############################################################################
# 4. Save the Document
###############################################################################
Out-RoyalDocument -Document $doc -FileName $fileName
