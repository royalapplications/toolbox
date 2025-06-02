[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ErrorActionPreference = "Stop"
$results = Get-PasswordStatePassword -PasswordID "$DynamicCredential.EffectiveID$"
$results.Password = $results.GetPassword()
$results | Select-Object Username,Password | ConvertTo-Json -Depth 100 | Write-Output