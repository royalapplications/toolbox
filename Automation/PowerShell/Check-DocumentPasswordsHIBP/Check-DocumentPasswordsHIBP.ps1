<#
.SYNOPSIS
  Checks your document passwords against Have I Been Pwned.
.DESCRIPTION
  This script allows you to check all your document passwords against the famous and
  great service called "Have I been pwned?". More information about this service can
  be found at the official site at: https://haveibeenpwned.com

  For your own security not your full passwords will be submitted to HIBP. The first
  5 letters from each passwords are going to be hashed using SHA-1 and submitted to
  the HIBP-API. Afterwards the returned dataset will be checked if your full SHA-1
  hashed password is within the returned list. This way your full password will
  never leave your local machine.

  Good luck that there are no matches! If so - taking action is recommended!
.INPUTS
  The only required parameter is the path to the document file.
.OUTPUTS
  A list of the objects (the object names, not the actual passwords) which are found in the HIBP dataset.
.PARAMETER File
  The path to your document file.
.PARAMETER EncryptionPassword
  The Encryption password of the specified document, if required.
.PARAMETER LockdownPassword
  The Lockdown password of the specified document, if required.
.EXAMPLE
  C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz"
.EXAMPLE
  C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz" -EncryptionPassword "EncryptionP@ssw0rd"
.EXAMPLE
  C:\PS> .\Check-DocumentPasswordsHIBP.ps1 -File "servers.rtsz" -EncryptionPassword "EncryptionP@ssw0rd" -LockdownPassword "LockdownP@ssw0rd"
.NOTES
  Name:           Check-DocumentPasswordsHIBP
  Version:        0.1.2
  Author:         Patrik Kernstock
  Copyright:      (C) 2018 code4ward GmbH
  Creation Date:  April 25, 2018
  Modified Date:  May 7, 2019
  Changelog:      For exact script changelog please check out the git commits history at:
                  https://github.com/royalapplications/scripts/commits/master/powershell/Check-DocumentPasswordsHIBP/Check-DocumentPasswordsHIBP.ps1
  Support:        For support please check out the "Support" section in the README file here:
                  https://github.com/royalapplications/scripts/tree/master/README.md#support
  Credits:        + To mrik23 on GitHub for inspiration how to do HIBP-API calls (https://gist.github.com/mrik23/e8efe6dc9cdfe62c9d0bb84dc25288fa)
                  + Troy Hunt for his great HaveIBeenPwned.com service! Give him out a donation if you appreciate his service.
.LINK
  https://github.com/royalapplications/scripts/commits/master/powershell/Check-DocumentPasswordsHIBP/
#>

## PARAMETERS
param(
	[CmdletBinding()]

	# File path to document. Default: None.
	[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
	[String] $File,

	# Encryption Password. Default: Null.
	[Parameter(Mandatory=$false)]
	$EncryptionPassword = $null,

	# Lockdown Password. Default: Null.
	[Parameter(Mandatory=$false)]
	$LockdownPassword = $null
)

### OTHERS
# load module: Royal TS.
if (Get-Module -ListAvailable RoyalDocument.PowerShell) {
	# Check if module is available, if so, load it. This is when module got installed through PSGallery.
	Import-Module RoyalDocument.PowerShell

} elseif ([System.Environment]::OSVersion.Platform -eq "Win32NT") {
	# If not and when Windows platform, we try the legacy way.
	$psModulePaths = @()
	$psModulePaths += Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'Royal TS V5\RoyalDocument.PowerShell.dll'
	$psModulePaths += Join-Path -Path ${env:ProgramFiles(x86)} -ChildPath 'code4ward.net\Royal TS V4\RoyalDocument.PowerShell.dll'
	foreach ($psModulePath in $psModulePaths) {
		if (Test-Path $psModulePath) {
			Import-Module $psModulePath
			break
		}
	}
}

if (!(Get-Module "RoyalDocument.PowerShell")) {
	Write-Error "Required RoyalDocument module not loaded."
	Write-Output "Please make sure you have either the PowerShell module installed through"
	Write-Output "PSGallery (recommended), or have an older Royal TS release installed which still"
	Write-Output "ships the PowerShell module with the installer. See more info at PSGallery site at:"
	Write-Output "https://www.powershellgallery.com/packages/RoyalDocument.PowerShell/"
	Write-Output "Installation using PSGallery: $ Install-Module -Name RoyalDocument.PowerShell"
	Write-Output "Aborting."
	exit
}

# sanity checks
if (!(Test-Path $File)) {
	Write-Error "Royal Document '$File' does not exist. Please provide a existing file. Aborting." -Category OpenError -ErrorAction Stop
}
$RoyalDocFile = $File

# check if Encryption and Lockdown Password as Secured Strings
if ($null -ne $EncryptionPassword -and $EncryptionPassword -isnot [SecureString]) {
	$EncryptionPassword = $EncryptionPassword | ConvertTo-SecureString -Force -AsPlainText
}
if ($null -ne $LockdownPassword -and $LockdownPassword -isnot [SecureString]) {
	$LockdownPassword = $LockdownPassword | ConvertTo-SecureString -Force -AsPlainText
}

# if lockdown password specified, but no encryption password, something will go wrong later on anyway. so we just abort here.
if ($null -ne $LockdownPassword -and $null -eq $EncryptionPassword) {
	Write-Error "When providing lockdown password the encryption password is required too. Aborting." -Category OpenError -ErrorAction Stop
}

# To stay on the safe side: Force TLS 1.2 for upcoming API requests.
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

# Function to create SHA-1 hash from password string
Function Get-StringHashSHA1()
{
	# Credits and Thanks to mrik23 here! See credits above.
	[CmdletBinding()]
	Param (
		  [Parameter(Mandatory=$True)]
		  [String] $inputString
	)

	$Private:outputHash = [string]::Empty
	$hasher = New-Object -TypeName "System.Security.Cryptography.SHA1CryptoServiceProvider"
	$hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($inputString)) | ForEach-Object {
		$outputHash += $_.ToString("x2")
	}

	return $outputHash.ToUpper()
}

# Function to check the partial password hash against HIBP
function CheckPasswordWithHIBP()
{
	param(
		[string] $stringHash
	)

	# this is the hashPrefix what is being sent over to the HIBP API
	$hashPrefix = $stringHash.Substring(0, 5)
	# that is the rest of the string after the 5th char
	$hashSuffix = $stringHash.Substring(5)

	# Invoking the web request to HIBP
	try {
		$response = Invoke-RestMethod -Uri "https://api.pwnedpasswords.com/range/$($hashPrefix)" -Method Get -ErrorVariable errorRequest
	}
	catch {
		return "[!] Error checking password of object '$($objName)': $($errorRequest)"
	}

	# If we got any response from the API...
	if ($null -ne $response) {
		$findHashSuffix = $response.Contains($hashSuffix)
		if ($findHashSuffix -eq $true) {
			$result = $response.Substring(
				$response.IndexOf($hashSuffix),
				($response.IndexOf("`r`n", $response.IndexOf($hashSuffix)) - $response.IndexOf($hashSuffix))
			)
			$resultCount = ($result.Split(":"))[1]
			# oh noes. we found something.
			return [int] $resultCount
		}
		else {
			# hash prefix returned something, but not expected password
			return [int] 0
		}
	}
	else {
		# hash prefix returned zero results from HIBP
		return [int] 0
	}

	return "unknown error"
}

# prepare some stuff.
Write-Verbose "+ Preparing..."
Write-Progress -Activity "Initialization" -Status "Loading data..." -PercentComplete 0
# create store (container for any documents)
$store = New-RoyalStore -UserName "HIBP-Checker"

# here we have a list of hashed passwords and the object ids using it
$docHashedPasswords = @{}
# here we have a list of all objects with ID and name, which contain any passwords
$docObjNames = @{}

# open document
Write-Verbose "+ Loading document..."
$doc = Open-RoyalDocument -Store $store -FileName $RoyalDocFile -Password $EncryptionPassword -LockdownPassword $LockdownPassword
# check if loading worked
if ($null -eq $doc) {
	Write-Error -Message "Failed loading document. Missing Encryption/Lockdown password? Please check. Aborting." -Category OpenError -ErrorAction Stop
}

Write-Verbose "+ Loading password properties..."
# get all objects with passwords
$passwords = $doc.GetAllPasswordProperties()
$totalPasswordPropsMax = @($passwords).Count
$passwords | ForEach-Object {
	# HINT: no progress bar here as it noticable slows down the process here.
	# get the object.
	$obj = $_.Item1
	# get the cleartext password
	$clearPwd = $obj.GetPropertyValue($_.Item2)
	# check if passwords are not empty and are not any CustomProperties
	# INFO: CustomProperties can not be iteriated with PS-API as of now
	# TODO: REMEMBER OBJECT PROPERTY NAME
	if ($clearPwd -ne "" -and $_.Item2.Name -ne "CustomProperties") {
		# remember name for later result list
		$docObjNames[$obj.ID] = $obj.Name
		# now only save hashed password into memory
		$hashedPwd = Get-StringHashSHA1 -inputString $clearPwd
		# get rid of cleartext passwords in memory ASAP
		$clearPwd = $null
		# check if we already have that one hashed password in our list
		if ($docHashedPasswords[$hashedPwd] -eq $null) {
			# nope, we don't. create a new array here.
			$docHashedPasswords[$hashedPwd] = @()
		}
		# add the object ID to the list, so we know which objects are using the hashed password
		$docHashedPasswords[$hashedPwd] += $obj.ID
	}
}
# clear the passwords variable from memory ASAP
$passwords = $null
Write-Verbose "Total scanned password properties: $totalPasswordPropsMax"

# output some stats
# when using get_Count() here we get the actual size of the hashtable, duplicate passwords removed.
$totalPasswords = $docHashedPasswords.get_Count()
$totalObjects = $docObjNames.get_Count()
Write-Host "Total of unique passwords to check: $totalPasswords"
Write-Host "Total of objects with passwords found: $totalObjects"

# now we're checking the passwords...
Write-Verbose "+ Checking passwords against HIBP..."
$totalMatches = 0
$hashedPwdCount = 0
$docHashedPasswords.Keys | ForEach-Object {
	$hashedPwdCount++
	Write-Host "Checking password $hashedPwdCount/$totalPasswords..." -ForegroundColor Blue

	# progress bar. yaay!
	Write-Progress -Activity "Checking password property $hashedPwdCount of $totalPasswords..." -Status "Processing..." -PercentComplete (($hashedPwdCount / $totalPasswords) * 100)

	$hashMatches = CheckPasswordWithHIBP -stringHash $_
	# if we do not get any integer back, anything wrong happend.
	if ($hashMatches -isnot [int]) {
		Write-Error -Message " Error ocurred while checking: $hashMatches" -Category InvalidResult
		continue
	}

	# result, but 0 records found. Reason to be happy!
	if ($hashMatches -le 0) {
		Write-Host "  No matches. Good!" -ForegroundColor Green
	} else {
		# oh no, we got pwned. tell the user the bad truth... including how often and which objects are affected.
		$totalMatches += $hashMatches
		Write-Host " Password has been pwned ${hashMatches}x." -ForegroundColor Red
		Write-Host "  Objects affected:" -ForegroundColor Magenta
		$docHashedPasswords.Item($_) | ForEach-Object {
			Write-Host "   - $($docObjNames[$_])"
		}
	}
}

# ...and we're done.
Write-Verbose "+ Password check done."
Write-Progress -Activity "Scan finished" -Status "Work complete." -PercentComplete 100
if ($totalMatches -gt 0) {
	Write-Host "In total your passwords has been pwned ${totalMatches}x." -ForegroundColor Red
	Write-Host "Changing affected passwords is strongly recommended!" -ForegroundColor Red
} else {
	Write-Host "No matches found! Your used document passwords were not pwned. Yaay!" -ForegroundColor Green
}

# ...and we're done.
Write-Verbose "+ Done."

# FIN

# SIG # Begin signature block
# MIISdgYJKoZIhvcNAQcCoIISZzCCEmMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUmtxG1IUOsS94/pMyXaUyTDk6
# FcCggg7TMIIG6DCCBNCgAwIBAgIQd70OBbdZC7YdR2FTHj917TANBgkqhkiG9w0B
# AQsFADBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEp
# MCcGA1UEAxMgR2xvYmFsU2lnbiBDb2RlIFNpZ25pbmcgUm9vdCBSNDUwHhcNMjAw
# NzI4MDAwMDAwWhcNMzAwNzI4MDAwMDAwWjBcMQswCQYDVQQGEwJCRTEZMBcGA1UE
# ChMQR2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1
# IEVWIENvZGVTaWduaW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDLIO+XHrkBMkOgW6mKI/0gXq44EovKLNT/QdgaVdQZU7f9oxfnejlc
# wPfOEaP5pe0B+rW6k++vk9z44rMZTIOwSkRQBHiEEGqk1paQjoH4fKsvtaNXM9JY
# e5QObQ+lkSYqs4NPcrGKe2SS0PC0VV+WCxHlmrUsshHPJRt9USuYH0mjX/gTnjW4
# AwLapBMvhUrvxC9wDsHUzDMS7L1AldMRyubNswWcyFPrUtd4TFEBkoLeE/MHjnS6
# hICf0qQVDuiv6/eJ9t9x8NG+p7JBMyB1zLHV7R0HGcTrJnfyq20Xk0mpt+bDkJzG
# uOzMyXuaXsXFJJNjb34Qi2HPmFWjJKKINvL5n76TLrIGnybADAFWEuGyip8OHtyY
# iy7P2uKJNKYfJqCornht7KGIFTzC6u632K1hpa9wNqJ5jtwNc8Dx5CyrlOxYBjk2
# SNY7WugiznQOryzxFdrRtJXorNVJbeWv3ZtrYyBdjn47skPYYjqU5c20mLM3GSQS
# cnOrBLAJ3IXm1CIE70AqHS5tx2nTbrcBbA3gl6cW5iaLiPcDRIZfYmdMtac3qFXc
# AzaMbs9tNibxDo+wPXHA4TKnguS2MgIyMHy1k8gh/TyI5mlj+O51yYvCq++6Ov3p
# Xr+2EfG+8D3KMj5ufd4PfpuVxBKH5xq4Tu4swd+hZegkg8kqwv25UwIDAQABo4IB
# rTCCAakwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1Ud
# EwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFCWd0PxZCYZjxezzsRM7VxwDkjYRMB8G
# A1UdIwQYMBaAFB8Av0aACvx4ObeltEPZVlC7zpY7MIGTBggrBgEFBQcBAQSBhjCB
# gzA5BggrBgEFBQcwAYYtaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY29kZXNp
# Z25pbmdyb290cjQ1MEYGCCsGAQUFBzAChjpodHRwOi8vc2VjdXJlLmdsb2JhbHNp
# Z24uY29tL2NhY2VydC9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3J0MEEGA1UdHwQ6MDgw
# NqA0oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290
# cjQ1LmNybDBVBgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZo
# dHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAN
# BgkqhkiG9w0BAQsFAAOCAgEAJXWgCck5urehOYkvGJ+r1usdS+iUfA0HaJscne9x
# thdqawJPsz+GRYfMZZtM41gGAiJm1WECxWOP1KLxtl4lC3eW6c1xQDOIKezu86Jt
# vE21PgZLyXMzyggULT1M6LC6daZ0LaRYOmwTSfilFQoUloWxamg0JUKvllb0EPok
# ffErcsEW4Wvr5qmYxz5a9NAYnf10l4Z3Rio9I30oc4qu7ysbmr9sU6cUnjyHccBe
# jsj70yqSM+pXTV4HXsrBGKyBLRoh+m7Pl2F733F6Ospj99UwRDcy/rtDhdy6/KbK
# Mxkrd23bywXwfl91LqK2vzWqNmPJzmTZvfy8LPNJVgDIEivGJ7s3r1fvxM8eKcT0
# 4i3OKmHPV+31CkDi9RjWHumQL8rTh1+TikgaER3lN4WfLmZiml6BTpWsVVdD3FOL
# JX48YQ+KC7r1P6bXjvcEVl4hu5/XanGAv5becgPY2CIr8ycWTzjoUUAMrpLvvj19
# 94DGTDZXhJWnhBVIMA5SJwiNjqK9IscZyabKDqh6NttqumFfESSVpOKOaO4ZqUmZ
# XtC0NL3W+UDHEJcxUjk1KRGHJNPE+6ljy3dI1fpi/CTgBHpO0ORu3s6eOFAm9CFx
# ZdcJJdTJBwB6uMfzd+jF1OJV0NMe9n9S4kmNuRFyDIhEJjNmAUTf5DMOId5iiUgH
# 2vUwggfjMIIFy6ADAgECAgw0pEY3n3SHs9/hQR0wDQYJKoZIhvcNAQELBQAwXDEL
# MAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExMjAwBgNVBAMT
# KUdsb2JhbFNpZ24gR0NDIFI0NSBFViBDb2RlU2lnbmluZyBDQSAyMDIwMB4XDTI0
# MDIyNzE1MTYyNFoXDTI3MDIyNzE1MTYyNFowggEgMR0wGwYDVQQPDBRQcml2YXRl
# IE9yZ2FuaXphdGlvbjEQMA4GA1UEBRMHNTMxMzY0djETMBEGCysGAQQBgjc8AgED
# EwJBVDEXMBUGCysGAQQBgjc8AgECEwZWaWVubmExFzAVBgsrBgEEAYI3PAIBARMG
# Vmllbm5hMQswCQYDVQQGEwJBVDEPMA0GA1UECBMGVmllbm5hMQ8wDQYDVQQHEwZW
# aWVubmExGDAWBgNVBAkTD0dyaW1tZ2Fzc2UgMzkvMzEYMBYGA1UEChMPUm95YWwg
# QXBwcyBHbWJIMRgwFgYDVQQDEw9Sb3lhbCBBcHBzIEdtYkgxKTAnBgkqhkiG9w0B
# CQEWGnN0ZWZhbi5rb2VsbEByb3lhbGFwcHMuY29tMIICIjANBgkqhkiG9w0BAQEF
# AAOCAg8AMIICCgKCAgEA5+gaPFDuK28BayL0xvUfyhdNRhCd/G1qPxilMJco+tGO
# RWizRPovlODiWfsH6/Rcvl+Z9vhy1Ga5KzBqZOsJjOIlOgtiDBpx8V+4G0TbGGme
# Ie7Eyh2dIPUb2cdAPw58X/ceeGWdL0GLd3F/VcixDWXwIoDjVC4Wl8AKYmpeUl1N
# t+S18bbiHxHH9PBPVN5gOQZLxO6JudvYEanY2fTtS+C2bsCbEW3Z1ytiyN17a/TW
# pVCm0byLIdIT1+dHVnmnWBPiTtjN6r7cyKzgRtjB7d9cHfjZWHNdAlIh6dmpsB+i
# yW2pXUEGwDXU2YZtiGXmxxAUHSXeKqfHzDbpTYEEYNPFbU7Y8NBs8/frixrG3nuo
# oGnpNk2378T/7cV5m94VCz411qSw7tlCIVJdJKLa1i4rVgVhEpELmO6kqjM9JgAP
# TBHk2buVCeqhjpNFgQUfyJj5OG4kckHxeODnrXivzu/4xiVOv2b48v76xR/u6acr
# 2OLCJxZQNj5WyAjjftPo//pc2AkTQDQ8mQoK7Qaey0oXY5GZTVNlTkgpHfjEPAEO
# J7K3+jTuw/7m4WDOi7vbZYQKpLYimeNBp2KLbn/TvsdTWz6B3hUc1BExnVzdN+57
# XZNetd6RT9HzvdDqDkXT1w30yQXd0rFFe2J/pzw4h+9qo7Ip429cuICYaUqIst0C
# AwEAAaOCAd0wggHZMA4GA1UdDwEB/wQEAwIHgDCBnwYIKwYBBQUHAQEEgZIwgY8w
# TAYIKwYBBQUHMAKGQGh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0
# L2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAyMC5jcnQwPwYIKwYBBQUHMAGGM2h0dHA6
# Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1ZXZjb2Rlc2lnbmNhMjAyMDBV
# BgNVHSAETjBMMEEGCSsGAQQBoDIBAjA0MDIGCCsGAQUFBwIBFiZodHRwczovL3d3
# dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAHBgVngQwBAzAJBgNVHRMEAjAA
# MEcGA1UdHwRAMD4wPKA6oDiGNmh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vZ3Nn
# Y2NyNDVldmNvZGVzaWduY2EyMDIwLmNybDAlBgNVHREEHjAcgRpzdGVmYW4ua29l
# bGxAcm95YWxhcHBzLmNvbTATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBQlndD8WQmGY8Xs87ETO1ccA5I2ETAdBgNVHQ4EFgQUvmL3XL+0IhNyTwIbvE8k
# 6VZkVL4wDQYJKoZIhvcNAQELBQADggIBAE27Fdab5gR05j0zFXqgwct7afy9+wG/
# EIYEe7Oxvuwi3dBCak95gWyD8LIR2bS/qkpac7q7mN31AFjnFLIe7+1IP0Hs/3ng
# 3BHsqZL6QZ65AWQj0pBXfOJ3hEalo9mNQS0SGVpF1QAqYHP/ZymDW8FbpWioHfJc
# 3SoGh7UXbiC8BA56mbxY9H+7SsVfSBWU6l9UAI0oMWZYZXtVRlfosjfH5Aq4wRL3
# 1TenA7oNCy52DWhUAblLF69oi34msbuPobD22yKZZomK/g8Crzzlrhq9wW+61pBg
# qydlJfuXCjuBczdGosY8HStNdVnyOG1zDt0/eZBQSCLpB2QwhXeutvNOLR97bYtD
# ZqRAzRS0nV2idwRXNvZi4jBe0nZGY6azDy7b5BSdqUUOxSrlvIGcT7KbGn/qqCaa
# zBOwQdJYFBkjieXbGg6iDmv/JcmHJqcmDfKwPpXx6PEsjD1mWkB5INm3qnrj1pQv
# 3+XgUpeF9cDuqev4zy4UxNPt5m6U34rG72CRMsIDoNdXAlJCOdI5PEE+0VE4F/ss
# p2MyeoOm1iWLtWN0Jwx5EEijsSjrRUnoCa516HVe3e6Op+1gbvgykTLZ7ykrk9a+
# l7aaxS+Wj3ehBlLd9g1EQ73LkDjy/UGnce2rxdJGn2+qoZfL/CXAVGHP8S6mOmu9
# aZluxKCQphiyMYIDDTCCAwkCAQEwbDBcMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEyMDAGA1UEAxMpR2xvYmFsU2lnbiBHQ0MgUjQ1IEVW
# IENvZGVTaWduaW5nIENBIDIwMjACDDSkRjefdIez3+FBHTAJBgUrDgMCGgUAoHgw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQx
# FgQUJJ+FpHn2eMaYXoQ5iEpcFRAWi1IwDQYJKoZIhvcNAQEBBQAEggIAi5QT7VK8
# v/JM7OIhXKhCHXs8NNisBs/WrqoXgLPVKB2DSsogtzOGU0mRFl8Q2iROV6k/Lyez
# 4fmdABNGSigCyCMKLCbeft8BBsVYxBc2a2qLm6NkrWq7QT+ToADZvb5N59Qjn8AX
# nUI7KtIIjjgt+NENqt+0cexCJFc2daBHmgD7gCJdc4Rx/c2mYjGFhO3hG22A9qLx
# 7+BcDl+3r1J2TAnazdal4Vjthbwo2TierRsvuc/J2mmZkPgsaSAd5RorU9nm1Ajt
# 5GsXD+EIbAHp7+JAFGZOoMcIrG9eh9MZF6Gb2VXP9JNanBk5r9jCWLSTG3oF9+iy
# X7hU6q3VRKyE2bO1YQjZJhcRz1/8u/JMlHR+xXv62uU+KZpedzeo2cY/KKm6fiIQ
# QXIm8Nv95rX/ojPeUCmI3pwbRrjB7DDoifKeieRbtnw7W1bSFMpAV9ppQqoNTDTM
# pXNBMJpuPPEAfmrivXQY7+zmXKWrEmT0ug9HtjDfGrO7TRZU76K830p6K591ArAm
# G1ZqIYW+kog1kq7xKa6Nrj/5woZA+SJH5ywdPOM9HC0/ea2tKaFJJRAibxUbD2De
# UyhsfV1w6SMgYLZR8FHwbhCYL1KqJn5yMgisUyH85gb99MJzDXhpabMAy3W2/W4u
# zHfqYbtv3N89QTIAusGsjEZF1bVuBAhpO9M=
# SIG # End signature block
