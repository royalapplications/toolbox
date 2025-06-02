$ErrorActionPreference = "Stop"
$results = Get-PasswordStatePassword -preventauditing
$credentials = @()
foreach ($item in $results) {
    if ($item.Notes -like "-----BEGIN RSA PRIVATE KEY----*") {
        $credentials += [pscustomobject]@{
            Type           = "DynamicCredential"
            Name           = $item.Title
            ID             = $item.PasswordID
			Username       = ""
			Password       = ""
            KeyFileContent = $item.Notes
			Path = $item.TreePath
        }
  
    }
    else {
        $credentials += [pscustomobject]@{
            Type     = "DynamicCredential"
            Name     = $item.Title
			Username = ""
			Password = ""
            ID       = $item.PasswordID
			Path = $item.TreePath
        }
   
    }
}


$final = [pscustomobject]@{
    Objects = $credentials
}
$final | ConvertTo-Json -Depth 100 | Write-Output