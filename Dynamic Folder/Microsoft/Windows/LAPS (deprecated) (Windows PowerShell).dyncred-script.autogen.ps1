# ----------------------
# <auto-generated>
#    WARNING: this file was generated by an automated tool; manual edits will be lost when it is re-generated.
#
#    The source code below was extracted from `./LAPS (deprecated) (Windows PowerShell).rdfx`
#
#    Do not edit this file; instead update the scripts embedded in `./LAPS (deprecated) (Windows PowerShell).rdfx`
# </auto-generated>
# ----------------------

$ErrorActionPreference = "Stop"

Import-Module AdmPwd.PS

$Pass = Get-AdmPwdPassword -Computername $Target.Name$

$JSON = ""
$JSON += "{`n"
$JSON += "  `"Username`" : `".\\Administrator`",`n"
$JSON += "  `"Password`" : `"$($Pass.Password)`"`n"
$JSON += "}`n"

Write-Host $JSON


