$ErrorActionPreference = "Stop"

$computers = Import-Csv "$CustomProperty.CSVPath$"

$connections = @()

ForEach ($computer in $computers) {
    $name = $computer.Name
    $computerName = $computer.ComputerName
    $username = $computer.Username
    $password = $computer.Password

    $connection = New-Object pscustomobject -Property @{
        "Type" = "TerminalConnection";
        "TerminalConnectionType" = "SSH";
        "Name" = $name;
        "ComputerName" = $computerName;
        "Username" = $username;
        "Password" = $password;
    }

    $connections += $connection
}

@{
    Objects = $connections
} |
ConvertTo-Json -Depth 100 |
Write-Host