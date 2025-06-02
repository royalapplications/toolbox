$ErrorActionPreference = "Stop"

# get data
$account = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$domain = $account.split("\")[0]
$username = $account.split("\")[1]

# output objects
@{
    Objects = @(
        @{
            ID = "CURRENT_DOMUSER";
            Type = "Credential";
            Name = "Current UserName with domain";
            Username = $account;
            Password = "";
            Path = "/";
            IconName = "VMware Clarity/Core/Avatar Solid";
            Description = "This reflects the current logged-on user account, including domain.";
            CustomProperties = @{
                DOMAIN = $domain;
                USERNAME = $username;
            }
        },
        @{
            ID = "CURRENT_USERNAME";
            Type = "Credential";
            Name = "Current UserName without domain";
            Username = $username;
            Password = "";
            Path = "/";
            IconName = "VMware Clarity/Core/Avatar Line";
            Description = "This reflects the current logged-on user account, without domain.";
            CustomProperties = @{
                DOMAIN = $domain;
            }
        }
    )
} | ConvertTo-Json -Depth 10 | Write-Host
