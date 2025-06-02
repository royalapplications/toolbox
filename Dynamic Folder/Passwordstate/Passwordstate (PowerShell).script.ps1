$ErrorActionPreference = "Stop"

function Get-Credential ($passwordObject, $createDynamicCredential) {
    $credentialID = $passwordObject.PasswordID
	$credentialName = $passwordObject.Title
	$username = ""
	$password = ""
	$url = $passwordObject.URL
	$notes = $passwordObject.Notes

	$folderPath = ""
	
	if ($passwordObject.TreePath) {
		$folderPath = $passwordObject.TreePath
	}

	if ($passwordObject.PasswordList) {
		$folderPath += "\" + $passwordObject.PasswordList
	}

	$folderPath = $folderPath.TrimStart([char]'\').Trim()

	$objectType = "Credential"

	if ($createDynamicCredential) {
		$objectType = "DynamicCredential"
	} else {
		$username = $passwordObject.UserName
		$password = $passwordObject.Password
	}
    
    $credential = New-Object pscustomobject -Property @{
        "Type" = $objectType;
        "ID" = $credentialID;
        "Name" = $credentialName;
		"Path" = $folderPath;
		"Username" = $username;
		"Password" = $password;
		"URL" = $url;
		"Notes" = $notes;
    }

    return $credential
}

function Get-Entries($url, $apiKey, $passwordListID, $preventAuditing, $createDynamicCredential, $skipCertificateCheck) {
	$api = "$url/api"
	
    $headers = @{
        "APIKey" = $apiKey
	}

	$passwordsBasePath = "/passwords/"

	$queryAllParam = "QueryAll"

	$preventAuditingParam = "PreventAuditing=false"

	if ($preventAuditing) {
		$preventAuditingParam = "PreventAuditing=true"
	}
	
	if ($passwordListID -gt -1) {
		$urlPasswords = $api + $passwordsBasePath + $passwordListID + "?" + $queryAllParam + "&" + $preventAuditingParam
	} else {
		$urlPasswords = $api + $passwordsBasePath + "?" + $queryAllParam + "&" + $preventAuditingParam
	}
	
	$webRequestParams = @{}

	if ($skipCertificateCheck) {
		$webRequestParams["-SkipCertificateCheck"] = $true
	}

	$passwordObjectsJSON = Invoke-WebRequest -Uri $urlPasswords -Headers $headers @webRequestParams
	$passwordObjects = (ConvertFrom-Json $passwordObjectsJSON.Content)
	
	$storeObjects = @()

	ForEach ($passwordObject in $passwordObjects) {
		$credential = Get-Credential -passwordObject $passwordObject -createDynamicCredential $createDynamicCredential
		
		$storeObjects += $credential
	}
	
	$store = New-Object pscustomobject -Property @{
        "Objects" = $storeObjects;
    }

	$storeJSON = (ConvertTo-Json -InputObject $store -Depth 100)

    $storeJSON
}

$baseURL = "$CustomProperty.ServerURL$"
$apiKey = "$EffectivePassword$"
$passwordListID = "$EffectiveUsername$"
$skipCertificateCheck = "$CustomProperty.SkipCertificateCheck$" -like "yes"

Get-Entries -url $baseURL -apiKey $apiKey -passwordListID $passwordListID -preventAuditing $false -createDynamicCredential $true -skipCertificateCheck $skipCertificateCheck