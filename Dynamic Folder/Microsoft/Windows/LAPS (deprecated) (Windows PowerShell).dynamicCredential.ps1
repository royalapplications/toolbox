$ErrorActionPreference = "Stop"

Import-Module AdmPwd.PS

$Pass = Get-AdmPwdPassword -Computername $Target.Name$

$JSON = ""
$JSON += "{`n"
$JSON += "  `"Username`" : `".\\Administrator`",`n"
$JSON += "  `"Password`" : `"$($Pass.Password)`"`n"
$JSON += "}`n"

Write-Host $JSON


