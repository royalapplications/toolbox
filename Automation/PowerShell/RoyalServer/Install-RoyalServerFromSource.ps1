#Requires -Version 5.1
#Requires -RunAsAdministrator

<#
.SYNOPSIS
    This script helps configuring a new Royal Server
    based on an existing Server.

    The existing server is not modified in any way. 
    Decommissioning the source server is not done by this script.

.DESCRIPTION
    This script will perform the following steps:
      0. Pre-checks (stop local service, verify source server connectivity,
         verify admin credentials, connect to remote share)
      1. Install the current Royal Server from scratch
      2. Install the license
      3. Copy the configuration file from the source host
         (appsettings.json)
      4. Copy the configuration database from the source host
         (royalserverv4.db)
      5. Copy the hosted documents from the source host
         %programdata%\royalserver\documentstore
      6. Install certificates (exports from source server via
         PowerShell remoting using thumbprints from appsettings.json:
         CertThumbPrint, SecureGateway.GatewayFingerprint, and
         AdditionalBindings[].CertificateHash - deduplicates automatically)
      7. Check IP configuration and validate AdditionalBindings
         (removes root-level and SecureGateway bindings with IPs not available locally)
      8. Check/compare group memberships
      9. Check configured file system paths
        - Document root folder
        - Full request/response logging
        - File log
      10. Check the configured worker account and configure
          group memberships (Royal Server Users, Royal Server
          Gateway Users, Royal Server Administrators, Administrators)
      11. Start Royal Server service and verify it responds
          on the status endpoint (HTTP 200)

    Exit Codes
        0 = Success
        1 = Not running as Administrator
        2 = Cannot reach source server
        3 = Failed to connect to remote share
        4 = Credential is not admin on source server (or WinRM not enabled)
        5 = Required PowerShell module not found

    This software is provided 'as is', without any warranties
    or representations of any kind, whether express or implied,
    including but not limited to warranties of merchantability,
    fitness for a particular purpose, or non-infringement.

.CHANGELOG
    1.2.15 - 2026-01-13 - ms - Step 10: Skip Worker Account configuration in WhatIf mode.
                             - No credential prompts in preview mode.
                             - Updated -WhatIf parameter documentation.
                             - Step 10: Skip Worker Account configuration in Force mode.
                             - Keeps existing Worker Account from source server when -Force is specified.
                             - Updated -Force parameter documentation.
                             - Added TLS 1.2 security protocol for HTTPS downloads.
                             - Step 7: Auto-select IP index 0 and keep ports when -Force is specified.
                             - Fixed bug where port was undefined in Force mode.
                             - Enables fully non-interactive execution with -Force.
                             - Fixed WorkerCredential parameter transformation error.
                             - Step 11 now uses splatting to conditionally pass WorkerCredential.
                             - Prevents error when Step 10 returns null.
                             - Fixed MSI caching: Added validation for version extraction from URL.
                             - Fixed misleading log message about MSI deletion.
                             - Added AdditionalBindings validation in Step 7.
                             - Validates both root-level and SecureGateway.AdditionalBindings.
                             - Automatically removes bindings with IPs not available locally.
                             - Supports IPv4, IPv6, and wildcard addresses (0.0.0.0, ::, *).
                             - Logs warnings for each removed binding.
                             - Fixed Step 7 and Step 9 to use local config instead of remote.
                             - Step 7: Update-IpConfiguration now reads/writes local appsettings.json.
                             - Step 9: Check-ConfiguredFilePaths now reads local appsettings.json.
                             - Prevents unintended modification of source server configuration.
                             - Removed AutoConfirm logic completely from the script.
                             - Simplified Confirm-UserAction to only accept (y/n) prompts.
                             - Step 7: Added retry logic for IP and port selection with validation.
                             - Script no longer breaks on invalid input, offers retry to user.
                             - Added explicit validation for RoyalDocument.Powershell module.
                             - Displays clear error message with installation instructions if missing.
                             - Added exit code 5 for missing required module.
                             - Added Get-DomainInfo helper function to detect domain membership.
                             - Step 10: Worker Account prompt now shows actual domain name when domain-joined.
                             - Step 10: Context-aware prompts (domain vs workgroup).
                             - Renamed to Install-RoyalServerFromSource.ps1
                             - Updated all internal references and comments.
                             - Changed "migration" terminology to "installation" throughout.
    1.2.6 - 2026-01-12 - ms  - Step 9: Auto-create missing log directories.
                             - Step 10: Fixed group membership check using SID comparison.
                             - Step 10: Fixed adding accounts to groups with Get-AdsiPath helper.
    1.2.5 - 2026-01-12 - ms  - Fixed MSI download caching by using versioned filename.
    1.2.4 - 2026-01-12 - ms  - Fixed Test-RoyalServerInstalled to correctly detect existing installations.
    1.2.3 - 2026-01-12 - ms  - Added "Step X ->" prefix to step log headers for clearer progress tracking.
    1.2.2 - 2026-01-12 - ms  - Refactored pre-checks into Step0-PreCheck function for consistent step structure.
    1.2.1 - 2026-01-12 - ms  - Fixed Test-Connection compatibility for PowerShell 5.1 and 7+ by using .NET Ping class.
    1.2.0 - 2026-01-10 - ms  - Added WhatIf support using PowerShell ShouldProcess pattern (-WhatIf, -Confirm, -Force).
                             - Added debug explanations to all step functions.
                             - Added transcript logging for installation audit trail.
                             - Added exit codes for automation support (0=Success, 1=Not Admin, 2=Unreachable).
                             - Added #Requires statements for PowerShell version and administrator rights.
                             - Fixed SourceServer parameter being overwritten by hardcoded value.
                             - Fixed Step2-5 to properly check source/local paths before copying.
                             - Fixed Stop-RoyalServerService error handling and added ShouldProcess.
                             - Replaced Write-Host with Write-Log for consistent logging.
                             - Removed unused variables and dead code.
                             - Rewrote Step6 to auto-export certificates from source server via PowerShell remoting.
                             - Step6 now reads thumbprints from CertThumbPrint, SecureGateway.GatewayFingerprint,
                              and AdditionalBindings[].CertificateHash with automatic deduplication.
                             - Removed RoyalServerCertificate and SecureGatewayCertificate parameters.
                             - Renamed SourceServerWorkerAccount to SourceServerCredential.
                             - Added credential support for remote share access and PowerShell remoting.
                             - Added exit code 3 for failed remote share mapping.
                             - Added pre-check to verify credential is admin on source server (exit code 4).
    1.1.0 - 2026-01-09 - ms  - Added detection and optional uninstall of existing Royal Server installation.
                             - Implemented Step8-Compare-GroupMemberships to compare local group memberships between servers.
                             - Renamed all step functions to include step number prefix (e.g. Step1-Install-RoyalServer).
                             - Added Step10-Check-WorkerAccount to configure Worker Account group memberships.
                             - Added Step11-Start-RoyalServerService to start service and verify status endpoint.
    1.0.0 - 2025-12-10 - ms  - Initial release.

.PARAMETER SourceServer
    IP/Name of the existing Royal Server installation

.PARAMETER SourceServerCredential
    Credential (PSCredential) for connecting to the source server.
    This account must be a local administrator on the source server
    to access the admin share (C$) and export certificates.

.PARAMETER Force
    Skips all confirmation prompts and proceeds with all actions.
    - Step 7: Automatically selects IP index 0 (first available IP) and keeps existing ports
      for both Royal Server and Secure Gateway configurations.
    - Step 10: Skips Worker Account configuration (keeps existing Worker Account from source server).

.PARAMETER WhatIf
    Shows what changes would be made without actually making them.
    Use this to preview the installation steps.
    - Step 10: Skips Worker Account configuration (no credential prompts in preview mode).

.PARAMETER Confirm
    Prompts for confirmation before each state-changing action

.PARAMETER DebugLogging
    This parameter sets the Log Level to Debug

.EXAMPLE
    .\Install-RoyalServerFromSource.ps1 -SourceServer 10.1.2.1
        -SourceServerCredential $cred
        -DebugLogging

.NOTES
    Author:        RoyalApps/Michael Seirer (ms)
    Requires:      PowerShell 5.1+ or PowerShell Core 7+,
                   RoyalDocument.Powershell module,
                   SourceServerCredential must be a local administrator on the
                   source server (for admin share access and certificate export)
#>
#------------------------------------------------------------
#region [ Parameters ]
#------------------------------------------------------------

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Hostname or IP address of the source Royal Server to install from.")]
    [string]$SourceServer = "127.0.0.1",
    [Parameter(Mandatory=$true)]
    [PSCredential]$SourceServerCredential,
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    [Parameter(Mandatory=$false)]
    [switch]$DebugLogging
    )

$ErrorActionPreference = "Stop"

#------------------------------------------------------------
# Configure TLS 1.2 for Secure HTTPS Downloads
#------------------------------------------------------------
# Force TLS 1.2 for web requests (required for downloading Royal Server MSI from royalapps.com)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#------------------------------------------------------------
# Validate Required PowerShell Module
#------------------------------------------------------------
$requiredModule = "RoyalDocument.Powershell"
$module = Get-Module -ListAvailable -Name $requiredModule

if (-not $module) {
    Write-Host ""
    Write-Host "ERROR: Required PowerShell module '$requiredModule' is not installed." -ForegroundColor Red
    Write-Host ""
    Write-Host "This script requires the RoyalDocument.Powershell module to function." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To install the module, run:" -ForegroundColor Cyan
    Write-Host "  Install-Module -Name RoyalDocument.Powershell -Scope CurrentUser" -ForegroundColor White
    Write-Host ""
    Write-Host "Or download it from:" -ForegroundColor Cyan
    Write-Host "  https://www.powershellgallery.com/packages/RoyalDocument.PowerShell" -ForegroundColor White
    Write-Host ""
    exit 5
}

Import-Module RoyalDocument.Powershell -ErrorAction Stop

$RemoteShare = "C$\ProgramData\RoyalServer"
$RemoteProgramData = "\\$SourceServer\$RemoteShare"
$LocalPath = "C:\ProgramData\RoyalServer"

$Step0Label = "Pre-Checks"
$Step1Label = "Install latest Royal Server"
$Step2Label = "Install Royal Server Licenses"
$Step3Label = "Copy Royal Server Configuration"
$Step4Label = "Copy Royal Server Database"
$Step5Label = "Copy Document Store"
$Step6Label = "Install Certificates"
$Step7Label = "Adapt IP Configurations"
$Step8Label = "Compare Group Memberships"
$Step9Label = "Check Configured Paths"
$Step10Label = "Check Worker Account"
$Step11Label = "Start Royal Server Service"

$ArrowDown = "=>"

#------------------------------------------------------------
#region [ Helper Functions ]
#------------------------------------------------------------

# General helpers
function Write-Log
{
    param (
        [string]$Message,
        [ValidateSet("DBG", "INF", "WRN", "ERR")]
        [string]$Level = "INF",
        [Parameter(Mandatory=$false)]
        [switch]$NoNewline
    )

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "[$timestamp][$Level] $Message"

    $params = @{ Object = $logMessage }
    if ($NoNewline) { $params.Add('NoNewline', $true) }

    switch ($Level) {
        "DBG" { $params.Add("ForegroundColor", "Gray") }
        "INF"  { $params.Add("ForegroundColor", "Cyan") }
        "WRN"  { $params.Add("ForegroundColor", "Yellow") }
        "ERR" { $params.Add("ForegroundColor", "Red") }
    }
    if( ($DebugLogging -eq $true -and $Level -eq "DBG") -or ($Level -eq "INF" -or $Level -eq "WRN" -or $Level -eq "ERR"))
    {
        Write-Host @params
    }
}

function Confirm-UserAction
{
    param(
        [string]$Message
    )

    # WhatIf mode - return true to let flow continue, ShouldProcess will handle the actual skip
    if ($WhatIfPreference) {
        return $true
    }

    # Force mode - skip confirmation
    if ($Force) {
        return $true
    }

    Write-Host "$Message (y/n): " -NoNewline
    $answer = Read-Host

    switch -Regex ($answer) {
        '^[yY]$' {
            return $true
        }
        default {
            return $false
        }
    }
}

# Pre-step helpers (Step 0)
function Test-SmbPort
{
    param([string]$Target)

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $async = $client.BeginConnect($Target, 445, $null, $null)
        $wait  = $async.AsyncWaitHandle.WaitOne(3000)      # 3 second timeout

        if ($wait -and $client.Connected) {
            $client.Close()
            return $true
        } else {
            $client.Close()
            return $false
        }
    } catch {
        return $false
    }
}

function Test-SourceServerConnectivity
{
    Write-Log "    Checking network connectivity to $SourceServer ..."
    try {
        $pingResult = [System.Net.NetworkInformation.Ping]::new().Send($SourceServer, 3000)
        $ping = ($pingResult.Status -eq [System.Net.NetworkInformation.IPStatus]::Success)
    } catch {
        $ping = $false
    }
    if (-not $ping) {
        Write-Host ([char]0x2198)
        Write-Log "    $ArrowDown Existing Royal Server '$SourceServer' cannot be reached - Ping failed. Host unreachable." -Level ERR
        return $false
    }
    else {
        Write-Log "    $ArrowDown Existing Royal Server '$SourceServer' can be pinged. Continuing."
    }

    $connectivity = Test-SmbPort -Target $SourceServer
    if(-not $connectivity)
    {
        Write-Log "    Existing Royal Server '$SourceServer' cannot be reached (using port 445 for SMB)." -Level Err
        Write-Log "    Port 445 is closed or filtered. Admin shares may not be reachable." -Level ERR
        return $false
    }
    return $true
}

function Stop-RoyalServerService
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $ServiceName = "RoyalServer"

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Log "    Royal Server service not found." -Level DBG
        return
    }

    if ($service.Status -eq "Running")
    {
        if ($PSCmdlet.ShouldProcess("RoyalServer service", "Stop")) {
            Write-Log "Stopping RoyalServer service..." -Level INF
            Stop-Service -Name $ServiceName -Force -ErrorAction Stop

            # Wait for service to stop (max 30 seconds)
            $timeout = 30
            $elapsed = 0
            while ($elapsed -lt $timeout) {
                Start-Sleep -Seconds 1
                $elapsed++
                $service = Get-Service -Name $ServiceName
                if ($service.Status -ne "Running") {
                    break
                }
            }

            if ($service.Status -eq "Running") {
                Write-Log "Royal Server Service could not be stopped within $timeout seconds. Please check manually." -Level ERR
            }
            else {
                Write-Log "Royal Server Service was stopped successfully." -Level INF
            }
        }
    }
    else {
        Write-Log "    Royal Server service is not running." -Level DBG
    }
}

# Step 1 helpers
function Find-RoyalServerDownloadLink
{
    try {
        # Download the page content
        $html = Invoke-WebRequest -Uri "https://royalapps.com/server/main/download" -UseBasicParsing -ErrorAction Stop

        # Parse all <a> tags with href
        $links = $html.Links | ForEach-Object { $_.href } | Where-Object { $_ -match ".*RoyalServerInstaller.*\.msi$" }

        if ($links.Count -eq 1) {
            Write-Log "    Found latest Royal Server MSI" -Level DBG
            return $links
        } else {
            Write-Log "    Latest Royal Server MSI not found" -Level WRN
        }
    }
    catch {
        Write-Log "    Error fetching or parsing page: $($_.Exception.Message)" -Level ERR
    }
}

function Get-InstalledRoyalServer
{
    <#
    .SYNOPSIS
        Returns information about any installed Royal Server, or $null if not found.
    #>
    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $items = Get-ChildItem $path | ForEach-Object {
                Get-ItemProperty $_.PsPath
            }

            foreach ($item in $items) {
                if ($item.DisplayName -and $item.DisplayName -like "Royal Server*") {
                    return $item
                }
            }
        }
    }
    return $null
}

function Uninstall-RoyalServer
{
    <#
    .SYNOPSIS
        Uninstalls the currently installed Royal Server.
    #>
    param(
        [Parameter(Mandatory=$true)]
        $InstalledProduct
    )

    $uninstallString = $InstalledProduct.UninstallString
    if (-not $uninstallString) {
        Write-Log "    No uninstall string found for Royal Server." -Level ERR
        return $false
    }

    Write-Log "    Uninstalling Royal Server $($InstalledProduct.DisplayVersion)..." -Level INF

    try {
        # MSI uninstall strings typically look like: MsiExec.exe /I{GUID} or MsiExec.exe /X{GUID}
        # We need to convert /I to /X for uninstall and add /qn for silent
        if ($uninstallString -match "MsiExec\.exe\s*/[IX](\{[A-F0-9\-]+\})") {
            $productCode = $matches[1]
            $arguments = "/X$productCode /qn /norestart /l*v $env:TEMP\rs_uninstall.log"

            Write-Log "    Running: msiexec.exe $arguments" -Level DBG
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop

            if ($process.ExitCode -eq 0) {
                Write-Log "    Uninstallation completed successfully." -Level INF
                return $true
            } else {
                Write-Log "    Uninstallation finished with exit code $($process.ExitCode). Check $env:TEMP\rs_uninstall.log for details." -Level ERR
                return $false
            }
        } else {
            Write-Log "    Uninstall string format not recognized: $uninstallString" -Level ERR
            return $false
        }
    }
    catch {
        Write-Log "    Error during uninstallation: $($_.Exception.Message)" -Level ERR
        return $false
    }
}

function Test-RoyalServerInstalled
{
    param(
        [string]$RequiredVersion
    )

    $RequiredVersion0 = Remove-LeadingZerosFromVersion -Version $RequiredVersion

    $paths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $installed = $null

    foreach ($path in $paths) {
        if (Test-Path $path) {
            $items = Get-ChildItem $path | ForEach-Object {
                Get-ItemProperty $_.PsPath
            }

            foreach ($item in $items) {
                # Search for "Royal Server" without version in name
                if ($item.DisplayName -and $item.DisplayName -like "Royal Server*") {
                    $installed = $item
                    break
                }
            }
        }

        if ($installed) {
            break
        }
    }

    # If software not found at all
    if (-not $installed) {
        return $false
    }

    # Compare versions
    try {
        $installedVersion = [version]$installed.DisplayVersion
        $requiredVersion = [version]$RequiredVersion0
        return ($installedVersion -ge $requiredVersion)
    } catch {
        return $false
    }
}

function Remove-LeadingZerosFromVersion
{
    param(
        [Parameter(Mandatory = $true)]
        [string]$Version
    )

    # Trim whitespace and split by '.'
    $segments = $Version.Trim() -split '\.'

    $strippedSegments = foreach ($seg in $segments) {
        # If numeric, convert to int to remove leading zeros
        if ($seg -match '^\d+$') {
            [int]$seg
        } else {
            # Leave non-numeric segments as-is
            $seg
        }
    }

    return $strippedSegments -join '.'
}

function Get-AdsiPath {
    param([string]$AccountName)

    if ($AccountName -match '^\.\\(.+)$') {
        # Local account: .\username -> WinNT://COMPUTERNAME/username
        return "WinNT://$env:COMPUTERNAME/$($Matches[1])"
    }
    elseif ($AccountName -match '^([^\\]+)\\(.+)$') {
        # Domain or computer account: DOMAIN\username -> WinNT://DOMAIN/username
        return "WinNT://$($Matches[1])/$($Matches[2])"
    }
    else {
        # Plain username, assume local
        return "WinNT://$env:COMPUTERNAME/$AccountName"
    }
}

function Get-AccountSid {
    param([string]$AccountName)

    try {
        $ntAccount = New-Object System.Security.Principal.NTAccount($AccountName)
        $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
        return $sid.Value
    }
    catch {
        return $null
    }
}

function Test-GroupMembershipBySid {
    param(
        [string]$GroupName,
        [string]$AccountSid
    )

    try {
        $group = [ADSI]"WinNT://./$GroupName,group"
        $members = @($group.Invoke("Members")) | ForEach-Object {
            try {
                $bytes = $_.GetType().InvokeMember("objectSid", 'GetProperty', $null, $_, $null)
                $sid = New-Object System.Security.Principal.SecurityIdentifier($bytes, 0)
                $sid.Value
            }
            catch {
                $null
            }
        }

        return ($members -contains $AccountSid)
    }
    catch {
        return $false
    }
}

function Get-DomainInfo {
    <#
    .SYNOPSIS
        Returns information about whether the machine is domain-joined.
    .OUTPUTS
        Returns a hashtable with IsDomainJoined (bool) and DomainName (string) properties.
    #>
    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        return @{
            IsDomainJoined = $computerSystem.PartOfDomain
            DomainName = $computerSystem.Domain
        }
    }
    catch {
        Write-Log "    Could not determine domain status: $($_.Exception.Message)" -Level WRN
        return @{
            IsDomainJoined = $false
            DomainName = $env:COMPUTERNAME
        }
    }
}

# Step 7 helpers
function Get-NestedJSONProperty {
    param (
        [Parameter(Mandatory)]
        [PSObject]$Object,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $current = $Object
    foreach ($part in $Path -split '\.') {
        if ($null -eq $current) { return $null }
        $current = $current.$part
    }
    return $current
}

function Set-NestedJSONProperty {
    param (
        [Parameter(Mandatory)]
        [PSObject]$Object,

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        $Value
    )

    $parts = $Path -split '\.'
    $current = $Object

    for ($i = 0; $i -lt $parts.Count - 1; $i++) {
        $part = $parts[$i]

        if ($null -eq $current.$part) {
            $current.$part = @{}
        }

        $current = $current.$part
    }

    $current.($parts[-1]) = $Value
}

function Get-LocalIPAddresses {
    param (
        [ValidateSet("IPv4", "IPv6", "Both")]
        [string]$AddressFamily = "Both"
    )

    $families =
        if ($AddressFamily -eq "Both") {
            "IPv4", "IPv6"
        } else {
            $AddressFamily
        }

    Get-NetIPAddress `
        -AddressFamily $families `
        -PrefixOrigin Dhcp,Manual 
}

function Update-IpConfiguration
{
    param(
        [string]$configName,
        [string]$jsonPathIP,
        [string]$jsonPathPort
    )

    $localConfigPath = "$LocalPath\appsettings.json"
    if (Test-Path $localConfigPath)
    {
        # Load and parse JSON from local configuration
        $config = Get-Content $localConfigPath -Raw | ConvertFrom-Json

        $ipAddress = Get-NestedJSONProperty -Object $config -Path $jsonPathIP
        $port = Get-NestedJSONProperty -Object $config -Path $jsonPathPort

        Write-Log "    Currently configured $configName IP: {$ipAddress}:{$port}" -Level INF

        $ipv6Enabled = (Get-NetAdapter | ForEach-Object { (Get-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6).Enabled }) -contains $true
        $localIPs = Get-LocalIPAddresses -AddressFamily Both

        $list = @($localIPs.IPAddress)
        # add unspecified IP addresses
        $list += "0.0.0.0"
        if($ipv6Enabled) {
            $list += "::"
        }


        if ($list.Count -eq 0)
        {
            Write-Log "    No local IPv4 addresses found." -Level WRN
            return
        }

        # When -Force is specified, automatically select index 0 (first IP) and keep existing port
        if($Force)
        {
            $selection = 0
            $selectedPort = $port
            Write-Log "    Auto-selected IP index 0: $($list[$selection]) (Force mode)" -Level INF
            Write-Log "    Keeping existing port: $port (Force mode)" -Level INF
        }
        else
        {
            # Loop until valid IP selection is made
            $validSelection = $false
            while (-not $validSelection) {
                # Display IPs with index (redisplay on retry)
                Write-Log "    The following IPs are available on the system:" -Level INF
                for ($i = 0; $i -lt $list.Count; $i++) {
                    Write-Log "     [$i] $($list[$i])" -Level INF
                }

                $selection = Read-Host "Select the IP address index to use for $configName"

                if ($selection -notmatch '^\d+$') {
                    Write-Log "    Invalid input. Please enter a numeric value." -Level ERR
                    continue
                }

                $selectionNum = [int]$selection
                if ($selectionNum -lt 0 -or $selectionNum -ge $list.Count) {
                    Write-Log "    Invalid selection. Please enter a number between 0 and $($list.Count - 1)." -Level ERR
                    continue
                }

                $selection = $selectionNum
                $validSelection = $true
            }

            # Loop until valid port is entered
            $validPort = $false
            while (-not $validPort) {
                Write-Log "    Specify the port (ENTER for keeping {$port}):" -Level INF
                $selectedPort = Read-Host "Specify the port (ENTER for keeping {$port})"

                if("" -eq $selectedPort)
                {
                    $selectedPort = $port
                    $validPort = $true
                    continue
                }

                # Validate that the input is a numeric value
                if ($selectedPort -notmatch '^\d+$') {
                    Write-Log "    Invalid port number. Port must be a numeric value." -Level ERR
                    continue
                }

                # Validate that the port number is within the valid range (1-65535)
                $portNumber = [int]$selectedPort
                if ($portNumber -lt 1 -or $portNumber -gt 65535) {
                    Write-Log "    Invalid port number. Port must be between 1 and 65535." -Level ERR
                    continue
                }

                $validPort = $true
            }
        }

        $selectedIP = $list[$selection]

       

        Set-NestedJSONProperty -Object $config -Path $jsonPathIP -Value $selectedIP
        Set-NestedJSONProperty -Object $config -Path $jsonPathPort -Value $selectedPort

        # Convert back to JSON and save to local configuration file
        $config | ConvertTo-Json -Depth 100 | Set-Content $localConfigPath -Encoding UTF8

        Write-Log "    Using $configName IP: {$selectedIP}:{$port}" -Level INF

    }

}

#------------------------------------------------------------
#endregion [ Helper Functions ]
#------------------------------------------------------------

#------------------------------------------------------------
#region [ Step Functions ]
#------------------------------------------------------------

function Start-Step0-PreCheck
{
    <#
    .SYNOPSIS
        Performs pre-flight checks before installation can proceed.
    .DESCRIPTION
        This step verifies all prerequisites are met:
        - Stops the local Royal Server service if running
        - Tests network connectivity to the source server
        - Verifies the provided credential has admin rights on the source server
        - Establishes connection to the remote admin share
    .OUTPUTS
        Returns 0 on success, or an exit code (1-4) on failure.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Log "Step 0 -> $Step0Label ..." -Level INF
    Write-Log "    This step performs pre-flight checks: stops local Royal Server service, verifies source server connectivity, validates admin credentials on source, and connects to the remote admin share." -Level DBG

    # Check if running as administrator
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if ($IsAdmin) {
        Write-Log "    Running as Administrator." -Level DBG
    } else {
        Write-Log "    Not running as Administrator. Aborting." -Level ERR
        Write-Log "$Step0Label - failed." -Level ERR
        return 1
    }

    # Stop local Royal Server service if running
    Stop-RoyalServerService

    # Check if we can reach the source server
    $connectivity = Test-SourceServerConnectivity
    if (-not $connectivity) {
        Write-Log "    Cannot reach $SourceServer - aborting." -Level ERR
        Write-Log "$Step0Label - failed." -Level ERR
        return 2
    }

    # Verify credential is admin on source server
    Write-Log "    Verifying credential is administrator on source server ..." -Level INF
    try {
        $isRemoteAdmin = Invoke-Command -ComputerName $SourceServer -Credential $SourceServerCredential -ScriptBlock {
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } -ErrorAction Stop

        if (-not $isRemoteAdmin) {
            Write-Log "    $ArrowDown Credential is not a local administrator on $SourceServer - aborting." -Level ERR
            Write-Log "$Step0Label - failed." -Level ERR
            return 4
        }
        Write-Log "    $ArrowDown Credential verified as administrator on source server." -Level INF
    } catch {
        Write-Log "    $ArrowDown Failed to verify credential on source server: $_" -Level ERR
        Write-Log "    $ArrowDown Ensure WinRM is enabled on the source server and the credential is valid." -Level ERR
        Write-Log "$Step0Label - failed." -Level ERR
        return 4
    }

    # Connect to remote share with credentials
    Write-Log "    Connecting to remote share $RemoteProgramData ..." -Level INF
    try {
        $netUser = $SourceServerCredential.UserName
        $netPass = $SourceServerCredential.GetNetworkCredential().Password
        $null = net use $RemoteProgramData /user:$netUser $netPass 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "net use failed with exit code $LASTEXITCODE"
        }
        Write-Log "    $ArrowDown Connected to remote share successfully." -Level INF
    } catch {
        Write-Log "    $ArrowDown Failed to connect to remote share: $_" -Level ERR
        Write-Log "    $ArrowDown Ensure the credential has local administrator rights on the source server." -Level ERR
        Write-Log "$Step0Label - failed." -Level ERR
        return 3
    }

    Write-Log "Step 0 -> $Step0Label - done." -Level INF
    return 0
}

function Start-Step1-Install-RoyalServer
{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    # https://royalapps.com/server/main/download
    # https://download.royalapps.com/RoyalServer/RoyalServerInstaller_5.03.51029.0.msi

    Write-Log "Step 1 -> $Step1Label ..." -Level INF
    Write-Log "    This step downloads the latest Royal Server MSI from royalapps.com, checks for existing installations (offering to uninstall if found), and performs a silent installation of the new version." -Level DBG

    # Check for existing Royal Server installation
    $existingInstall = Get-InstalledRoyalServer
    if ($existingInstall) {
        Write-Log "    Found existing Royal Server installation: $($existingInstall.DisplayName) (Version: $($existingInstall.DisplayVersion))" -Level WRN
        Write-Log "    It is recommended to uninstall it before installing a new version." -Level WRN

        if (Confirm-UserAction -Message "Do you want to uninstall the existing Royal Server first?") {
            if ($PSCmdlet.ShouldProcess("Royal Server $($existingInstall.DisplayVersion)", "Uninstall")) {
                $uninstallResult = Uninstall-RoyalServer -InstalledProduct $existingInstall
                if (-not $uninstallResult) {
                    Write-Log "    Uninstallation failed. Please uninstall manually before proceeding." -Level ERR
                    return
                }
                # Wait a moment for the uninstall to fully complete
                Write-Log "    Waiting for uninstallation to complete..." -Level INF
                Start-Sleep -Seconds 5
            }
        } else {
            Write-Log "    Continuing without uninstalling existing installation." -Level WRN
        }
    }

    # Ask user before fetching download link
    if (-not (Confirm-UserAction -Message "Proceed with: $Step1Label ?"))
    {
        Write-Log "    Installation cancelled" -Level INF
        Write-Log "$Step1Label - done." -Level INF
        return
    }

    # Only fetch download link when user confirmed installation
    Write-Log "    Fetching latest Royal Server download link..." -Level DBG
    $MsiUrl = Find-RoyalServerDownloadLink
    if (-not $MsiUrl) {
        Write-Log "    Could not find Royal Server download link." -Level ERR
        Write-Log "Step 1 -> $Step1Label - done." -Level INF
        return
    }

    $rsLatestVersion = [regex]::Match($MsiUrl, '\d+\.\d+\.\d+\.\d+').Value

    if ([string]::IsNullOrWhiteSpace($rsLatestVersion)) {
        Write-Log "    Could not extract version number from URL: $MsiUrl" -Level ERR
        Write-Log "    Step 1 -> $Step1Label - done." -Level INF
        return
    }

    Write-Log "    Latest Royal Server version available: $rsLatestVersion" -Level INF

    # Construct versioned destination path
    $Destination = "$env:TEMP\RoyalServerInstaller_$rsLatestVersion.msi"

    # Check if already installed at this version
    $rsInstalled = Test-RoyalServerInstalled -RequiredVersion $rsLatestVersion
    if($rsInstalled)
    {
        Write-Log "    Royal Server $rsLatestVersion is already installed. Skipping..." -Level INF
        Write-Log "Step 1 -> $Step1Label - done." -Level INF
        return
    }

    # Proceed with download and install
    if ($PSCmdlet.ShouldProcess("Royal Server $rsLatestVersion", "Download and Install")) {
        try {
            if (Test-Path $Destination -PathType Leaf)
            {
                Write-Log "    MSI already downloaded: $Destination" -Level INF
            } else {
                Write-Log "    Downloading $MsiUrl..." -Level INF
                Invoke-WebRequest -Uri $MsiUrl -OutFile $Destination -UseBasicParsing -ErrorAction Stop
                Write-Log "    Download complete: $Destination" -Level INF
            }

            Write-Log "    Starting silent installation..." -Level INF
            $arguments = "/i `"$Destination`" /qn /norestart /l*v $env:TEMP\rs_install.log"

            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -ErrorAction Stop

            if ($process.ExitCode -eq 0) {
                Write-Log "    Installation completed successfully." -Level INF
                # Keep MSI for subsequent runs to avoid re-downloading
                Write-Log "    MSI kept at: $Destination" -Level DBG
            } else {
                Write-Log "    Installation finished with exit code $($process.ExitCode). Check $env:TEMP\rs_install.log for details." -Level ERR
            }
        }
        catch {
            Write-Log "    Error: $($_.Exception.Message)" -Level ERR
        }
    }

    Write-Log "Step 1 -> $Step1Label - done." -Level INF
}

function Start-Step2-Copy-RoyalServerLicenses
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    # 2. install the license
    #    copy over all *.lic files from source server to %programdata%\royalserver\licenses
    $LocalLicensePath = "$LocalPath\Licenses"
    $RemoteLicensePath = "$RemoteProgramData\Licenses"

    Write-Log "Step 2 -> $Step2Label ..." -Level INF
    Write-Log "    This step copies all license files (*.lic) from the source server's Licenses folder to the local Royal Server Licenses directory." -Level DBG

    # Check if remote license path exists
    if (-not (Test-Path $RemoteLicensePath)) {
        Write-Log "    Remote license path '$RemoteLicensePath' not found. Skipping." -Level WRN
        Write-Log "Step 2 -> $Step2Label - done." -Level INF
        return
    }

    # Ensure local license directory exists
    if (-not (Test-Path $LocalLicensePath)) {
        New-Item -ItemType Directory -Path $LocalLicensePath -Force | Out-Null
    }

    # Copy license files from source
    $licenses = Get-ChildItem -Path $RemoteLicensePath -Filter *.lic -ErrorAction SilentlyContinue

    if ($licenses.Count -eq 0) {
        Write-Log "    No license files found in '$RemoteLicensePath'." -Level WRN
        Write-Log "Step 2 -> $Step2Label - done." -Level INF
        return
    }

    foreach($license in $licenses)
    {
        if ($PSCmdlet.ShouldProcess($license.Name, "Copy license file to $LocalLicensePath")) {
            Write-Log "    Copying '$($license.Name)' to '$LocalLicensePath'"
            Copy-Item -Path $license.FullName -Destination $LocalLicensePath -Force
        }
    }
    Write-Log "Step 2 -> $Step2Label - done." -Level INF
}

function Start-Step3-Copy-RoyalServerConfiguration
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-Log "Step 3 -> $Step3Label ..." -Level INF
    Write-Log "    This step copies the appsettings.json configuration file from the source server to the local Royal Server installation, preserving all server settings." -Level DBG

    # Check if source file exists
    if (-not (Test-Path "$RemoteProgramData\appsettings.json")) {
        Write-Log "    Source configuration file '$RemoteProgramData\appsettings.json' not found. Skipping." -Level WRN
        Write-Log "Step 3 -> $Step3Label - done." -Level INF
        return
    }

    # Check if local file exists and ask for confirmation
    if (Test-Path "$LocalPath\appsettings.json")
    {
        if (-not (Confirm-UserAction -Message "Local configuration file exists. Overwrite?"))
        {
            Write-Log "    $Step3Label skipped." -Level INF
            return
        }
    }
    if ($PSCmdlet.ShouldProcess("$LocalPath\appsettings.json", "Copy configuration from $RemoteProgramData")) {
        Copy-Item "$RemoteProgramData\appsettings.json" -Destination $LocalPath -Force
    }
    Write-Log "Step 3 -> $Step3Label - done." -Level INF
}

function Start-Step4-Copy-RoyalServerDatabase
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-Log "Step 4 -> $Step4Label ..." -Level INF
    Write-Log "    This step copies the Royal Server database file (royalserverv4.db) from the source server, which contains user configurations, permissions, and server settings." -Level DBG

    # Check if source file exists
    if (-not (Test-Path "$RemoteProgramData\royalserverv4.db")) {
        Write-Log "    Source database file '$RemoteProgramData\royalserverv4.db' not found. Skipping." -Level WRN
        Write-Log "Step 4 -> $Step4Label - done." -Level INF
        return
    }

    # Check if local file exists and ask for confirmation
    if (Test-Path "$LocalPath\royalserverv4.db")
    {
        if (-not (Confirm-UserAction -Message "Local database file exists. Overwrite?"))
        {
            Write-Log "    $Step4Label skipped." -Level INF
            return
        }
    }
    if ($PSCmdlet.ShouldProcess("$LocalPath\royalserverv4.db", "Copy database from $RemoteProgramData")) {
        Copy-Item "$RemoteProgramData\royalserverv4.db" -Destination $LocalPath -Force
    }
    Write-Log "Step 4 -> $Step4Label - done." -Level INF
}

function Start-Step5-Copy-DocumentStore
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-Log "Step 5 -> $Step5Label ..." -Level INF
    Write-Log "    This step copies the DocumentStore folder from the source server, which contains all hosted Royal Documents that clients can access via the server." -Level DBG

    # Check if source folder exists
    if (-not (Test-Path "$RemoteProgramData\DocumentStore")) {
        Write-Log "    Source document store '$RemoteProgramData\DocumentStore' not found. Skipping." -Level WRN
        Write-Log "Step 5 -> $Step5Label - done." -Level INF
        return
    }

    # Check if local folder exists and ask for confirmation
    if (Test-Path "$LocalPath\DocumentStore")
    {
        if (-not (Confirm-UserAction -Message "Local Document Store exists. Overwrite?"))
        {
            Write-Log "    $Step5Label skipped." -Level INF
            return
        }
    }
    if ($PSCmdlet.ShouldProcess("$LocalPath\DocumentStore", "Copy document store from $RemoteProgramData")) {
        Copy-Item "$RemoteProgramData\DocumentStore\" -Destination $LocalPath -Recurse -Force
    }
    Write-Log "Step 5 -> $Step5Label - done." -Level INF
}

function Start-Step6-Install-RoyalServerCertificate
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-Log "Step 6 -> $Step6Label ..." -Level INF
    Write-Log "    This step reads certificate thumbprints (CertThumbPrint, SecureGateway.GatewayFingerprint) from appsettings.json, exports them from the source server, and imports them into the local certificate store." -Level DBG

    $storePath = "Cert:\LocalMachine\My"
    $configPath = "$LocalPath\appsettings.json"

    # Check if config file exists (should have been copied in Step 3)
    if (-not (Test-Path $configPath)) {
        Write-Log "    Configuration file not found at $configPath. Run Step 3 first." -Level ERR
        Write-Log "Step 6 -> $Step6Label - done." -Level INF
        return
    }

    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # Define certificate sources (add new certificates here)
    $certificateSources = @(
        @{ Name = "Royal Server"; Path = "CertThumbPrint" }
        @{ Name = "Secure Gateway"; Path = "SecureGateway.GatewayFingerprint" }
    )

    # Collect unique thumbprints and track which services use them
    $uniqueThumbprints = @{}
    foreach ($source in $certificateSources) {
        $thumbprint = Get-NestedJSONProperty -Object $config -Path $source.Path
        if (-not [string]::IsNullOrWhiteSpace($thumbprint)) {
            if ($uniqueThumbprints.ContainsKey($thumbprint)) {
                $uniqueThumbprints[$thumbprint].Names += $source.Name
            } else {
                $uniqueThumbprints[$thumbprint] = @{ Names = @($source.Name); Thumbprint = $thumbprint }
            }
        }
    }

    # Process AdditionalBindings certificates
    $additionalBindings = $config.AdditionalBindings
    if ($additionalBindings) {
        for ($i = 0; $i -lt $additionalBindings.Count; $i++) {
            $binding = $additionalBindings[$i]
            $thumbprint = $binding.CertificateHash
            if (-not [string]::IsNullOrWhiteSpace($thumbprint)) {
                $bindingName = "AdditionalBinding[$i] ($($binding.IpAddress):$($binding.Port))"
                if ($uniqueThumbprints.ContainsKey($thumbprint)) {
                    $uniqueThumbprints[$thumbprint].Names += $bindingName
                } else {
                    $uniqueThumbprints[$thumbprint] = @{ Names = @($bindingName); Thumbprint = $thumbprint }
                }
            }
        }
    }

    # Build list and log duplicates
    $thumbprints = @()
    foreach ($entry in $uniqueThumbprints.Values) {
        $displayName = $entry.Names -join ", "
        if ($entry.Names.Count -gt 1) {
            Write-Log "    Certificate with thumbprint $($entry.Thumbprint) is used by: $displayName" -Level INF
        }
        $thumbprints += @{ Name = $displayName; Thumbprint = $entry.Thumbprint }
    }

    if ($thumbprints.Count -eq 0) {
        Write-Log "    No certificate thumbprints found in configuration." -Level WRN
        Write-Log "Step 6 -> $Step6Label - done." -Level INF
        return
    }

    foreach ($certInfo in $thumbprints) {
        $thumbprint = $certInfo.Thumbprint
        $certName = $certInfo.Name
        Write-Log "    Processing $certName certificate (Thumbprint: $thumbprint)..." -Level INF

        # Check if certificate is already installed locally
        $installedCert = Get-ChildItem $storePath -ErrorAction SilentlyContinue |
            Where-Object { $_.Thumbprint -eq $thumbprint }

        if ($installedCert) {
            Write-Log "    $certName certificate is already installed locally." -Level INF
            continue
        }

        # Try to export certificate from source server
        Write-Log "    Attempting to export certificate from $SourceServer..." -Level INF
        try {
            # Ask user for password to protect the PFX export (with confirmation)
            $securePassword = Read-Host "Enter password for $certName certificate export" -AsSecureString
            $securePasswordConfirm = Read-Host "Confirm password" -AsSecureString

            $tempPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
            )
            $tempPasswordConfirm = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
                [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePasswordConfirm)
            )

            if ($tempPassword -ne $tempPasswordConfirm) {
                Write-Log "    Entered Passwords do not match. Skipping $certName certificate." -Level ERR
                continue
            }

            Write-Log "    Please save this password somewhere secure (e.g. Royal TS/X) for future reference." -Level INF

            $certBytes = Invoke-Command -ComputerName $SourceServer -Credential $SourceServerCredential -ScriptBlock {
                param($tp, $pw)
                $cert = Get-ChildItem -Path Cert:\LocalMachine\My -ErrorAction Stop |
                    Where-Object { $_.Thumbprint -eq $tp }
                if (-not $cert) {
                    throw "Certificate not found in remote store"
                }
                if (-not $cert.HasPrivateKey) {
                    throw "Certificate does not have a private key"
                }
                # Check if private key is exportable (works for CSP keys)
                try {
                    if ($cert.PrivateKey -and $cert.PrivateKey.CspKeyContainerInfo -and -not $cert.PrivateKey.CspKeyContainerInfo.Exportable) {
                        throw "Private key is not marked as exportable"
                    }
                } catch [System.Security.Cryptography.CryptographicException] {
                    # CNG keys don't support CspKeyContainerInfo, try export anyway
                }
                # Export as PFX with password
                try {
                    $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pfx, $pw)
                } catch {
                    throw "Failed to export certificate. Private key may not be exportable: $_"
                }
            } -ArgumentList $thumbprint, $tempPassword -ErrorAction Stop

            # Save temporarily and import
            $tempPfxPath = "$env:TEMP\cert_$thumbprint.pfx"
            [System.IO.File]::WriteAllBytes($tempPfxPath, $certBytes)

            if ($PSCmdlet.ShouldProcess("$certName certificate with thumbprint $thumbprint", "Import to $storePath")) {
                Import-PfxCertificate -FilePath $tempPfxPath -CertStoreLocation $storePath -Password $securePassword -ErrorAction Stop | Out-Null
                Write-Log "    $certName certificate installed successfully." -Level INF
            }

            # Clean up temp file
            Remove-Item $tempPfxPath -Force -ErrorAction SilentlyContinue

        } catch {
            Write-Log "    Failed to export $certName certificate from source server: $_" -Level ERR
            Write-Log "    Manual steps required for thumbprint: $thumbprint" -Level WRN
            Write-Log "    1. On source server, export the certificate with private key to a .pfx file" -Level WRN
            Write-Log "    2. Copy the .pfx file to this server" -Level WRN
            Write-Log "    3. Import the certificate to Local Computer -> Personal Certificates" -Level WRN
            Write-Log "    You can use: Import-PfxCertificate -FilePath <path> -CertStoreLocation Cert:\LocalMachine\My" -Level WRN
        }
    }

    Write-Log "Step 6 -> $Step6Label - done." -Level INF
}

function Remove-InvalidAdditionalBindings
{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $localConfigPath = "$LocalPath\appsettings.json"
    if (-not (Test-Path $localConfigPath)) {
        Write-Log "    Configuration file not found at $localConfigPath." -Level WRN
        return
    }

    # Load configuration
    $config = Get-Content $localConfigPath -Raw | ConvertFrom-Json

    # Check if there are any AdditionalBindings to validate
    $hasRootBindings = $config.AdditionalBindings -and $config.AdditionalBindings.Count -gt 0
    $hasGatewayBindings = $config.SecureGateway -and $config.SecureGateway.AdditionalBindings -and $config.SecureGateway.AdditionalBindings.Count -gt 0

    if (-not $hasRootBindings -and -not $hasGatewayBindings) {
        Write-Log "    No AdditionalBindings configured." -Level DBG
        return
    }

    # Get all local IP addresses
    $localIPs = Get-LocalIPAddresses -AddressFamily Both
    $localIPList = @($localIPs.IPAddress)
    # Add wildcard addresses
    $localIPList += "0.0.0.0"
    $localIPList += "::"
    $localIPList += "*"

    Write-Log "    Checking AdditionalBindings for invalid IP addresses..." -Level INF

    $totalRemoved = 0
    $configChanged = $false

    # Process root-level AdditionalBindings
    if ($hasRootBindings) {
        $validBindings = @()
        $removedCount = 0

        foreach ($binding in $config.AdditionalBindings) {
            $bindingIP = $binding.IpAddress

            if ($localIPList -contains $bindingIP) {
                $validBindings += $binding
            } else {
                $removedCount++
                Write-Log "    WARNING: Removed Royal Server AdditionalBinding ${bindingIP}:$($binding.Port) - IP not available locally" -Level WRN
            }
        }

        if ($removedCount -gt 0) {
            $config.AdditionalBindings = $validBindings
            $totalRemoved += $removedCount
            $configChanged = $true
        }
    }

    # Process SecureGateway AdditionalBindings
    if ($hasGatewayBindings) {
        $validBindings = @()
        $removedCount = 0

        foreach ($binding in $config.SecureGateway.AdditionalBindings) {
            $bindingIP = $binding.IpAddress

            if ($localIPList -contains $bindingIP) {
                $validBindings += $binding
            } else {
                $removedCount++
                Write-Log "    WARNING: Removed Secure Gateway AdditionalBinding ${bindingIP}:$($binding.Port) - IP not available locally" -Level WRN
            }
        }

        if ($removedCount -gt 0) {
            $config.SecureGateway.AdditionalBindings = $validBindings
            $totalRemoved += $removedCount
            $configChanged = $true
        }
    }

    # Save configuration if changes were made
    if ($configChanged) {
        if ($PSCmdlet.ShouldProcess("appsettings.json", "Remove invalid AdditionalBindings")) {
            # Save the configuration
            $config | ConvertTo-Json -Depth 100 | Set-Content $localConfigPath -Encoding UTF8

            Write-Log "    Removed $totalRemoved invalid AdditionalBinding(s) from configuration." -Level WRN
        }
    } else {
        Write-Log "    All AdditionalBindings have valid IP addresses." -Level INF
    }
}

function Start-Step7-Update-IpConfigurations
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-Log "Step 7 -> $Step7Label ..." -Level INF
    Write-Log "    This step updates the IP address and port bindings in appsettings.json for both Royal Server and Secure Gateway to match the new server's network configuration. It also validates AdditionalBindings (both root-level and SecureGateway) and removes any entries with IPs that are not available locally." -Level DBG
    if ($PSCmdlet.ShouldProcess("appsettings.json", "Update Royal Server IP configuration")) {
        Update-IpConfiguration -configName "Royal Server" -jsonPathIP IPAddress -jsonPathPort Port
    }
    if ($PSCmdlet.ShouldProcess("appsettings.json", "Update Secure Gateway IP configuration")) {
        Update-IpConfiguration -configName "Secure Gateway" -jsonPathIP SecureGateway.GatewayIPAddress -jsonPathPort SecureGateway.GatewayPort
    }

    # Check and remove invalid AdditionalBindings
    Remove-InvalidAdditionalBindings

    Write-Log "Step 7 -> $Step7Label - done." -Level INF
}

function Start-Step8-Compare-GroupMemberships
{
    Write-Log "Step 8 -> $Step8Label ..." -Level INF
    Write-Log "    This step compares local Windows group memberships (Administrators, Royal Server Users, Royal Server Gateway Users, Royal Server Administrators) between source and local servers to identify missing members." -Level DBG

    # Groups that are typically relevant for Royal Server
    $groupsToCheck = @(
        "Administrators",
        "Royal Server Users",
        "Royal Server Gateway Users",
        "Royal Server Administrators"
    )

    try {
        # Get group memberships from source server
        Write-Log "    Retrieving group memberships from source server '$SourceServer'..." -Level INF

        $sourceGroups = @{}
        foreach ($groupName in $groupsToCheck) {
            try {
                $members = Invoke-Command -ComputerName $SourceServer -Credential $SourceServerCredential -ScriptBlock {
                    param($group)
                    $groupObj = [ADSI]"WinNT://./$group,group"
                    if ($groupObj.Path) {
                        @($groupObj.Invoke("Members")) | ForEach-Object {
                            $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                        }
                    }
                } -ArgumentList $groupName -ErrorAction SilentlyContinue

                $sourceGroups[$groupName] = @($members)
            }
            catch {
                Write-Log "    Could not retrieve members of '$groupName' from source server." -Level DBG
                $sourceGroups[$groupName] = @()
            }
        }

        # Get group memberships from local server
        Write-Log "    Retrieving group memberships from local server..." -Level INF

        $localGroups = @{}
        foreach ($groupName in $groupsToCheck) {
            try {
                $groupObj = [ADSI]"WinNT://./$groupName,group"
                if ($groupObj.Path) {
                    $members = @($groupObj.Invoke("Members")) | ForEach-Object {
                        $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
                    }
                    $localGroups[$groupName] = @($members)
                } else {
                    $localGroups[$groupName] = @()
                }
            }
            catch {
                Write-Log "    Could not retrieve members of '$groupName' from local server." -Level DBG
                $localGroups[$groupName] = @()
            }
        }

        # Compare group memberships
        Write-Log "    Comparing group memberships..." -Level INF
        $differencesFound = $false

        foreach ($groupName in $groupsToCheck) {
            $sourceMembers = $sourceGroups[$groupName]
            $localMembers = $localGroups[$groupName]

            # Find members in source but not in local
            $missingInLocal = $sourceMembers | Where-Object { $_ -and $_ -notin $localMembers }

            # Find members in local but not in source
            $extraInLocal = $localMembers | Where-Object { $_ -and $_ -notin $sourceMembers }

            if ($missingInLocal.Count -gt 0 -or $extraInLocal.Count -gt 0) {
                $differencesFound = $true
                Write-Log "    Group '$groupName' has differences:" -Level WRN

                $group = [ADSI]"WinNT://./$groupName,group"

                foreach ($member in $missingInLocal) {
                    Write-Log "      [-] Missing on local: $member" -Level WRN
                }
                foreach ($member in $extraInLocal) {
                    Write-Log "      [+] Extra on local: $member" -Level INF
                }
            } else {
                Write-Log "    Group '$groupName': OK (matches source)" -Level INF
            }
        }

        if (-not $differencesFound) {
            Write-Log "    All checked groups match between source and local server." -Level INF
        }
    }
    catch {
        Write-Log "    Error comparing group memberships: $($_.Exception.Message)" -Level ERR
        Write-Log "    Note: Remote comparison requires WinRM to be enabled on the source server." -Level WRN
    }

    Write-Log "Step 8 -> $Step8Label - done." -Level INF
}

function Start-Step9-Check-ConfiguredFilePaths
{
    Write-Log "Step 9 -> $Step9Label ..." -Level INF
    Write-Log "    This step verifies that configured file system paths (Document Store folder, Request/Response logging directory, File log directory) exist on the local system." -Level DBG

    $configPath = "$LocalPath\appsettings.json"
    $config = Get-Content $configPath -Raw | ConvertFrom-Json

    # document root folder
    $documentStoreFolder = Get-NestedJSONProperty -Object $config -Path "DocumentStore.DocumentStoreRootFolder"
    if ( -not (Test-Path $documentStoreFolder))
    {
        Write-Log "    Configured Document Store Folder '$documentStoreFolder' not found." -Level WRN
    }
    else
    {
        Write-Log "    Configured Document Store Folder '$documentStoreFolder' found." -Level INF
    }

    # fullrequestresponse logging
    $fullRequestResponseLoggingEnabled = Get-NestedJSONProperty -Object $config -Path "FullRequestResponseLogging"
    $fullRequestResponseLoggingDirectory = Get-NestedJSONProperty -Object $config -Path "FullRequestResponseLogDirectory"
    if($fullRequestResponseLoggingEnabled)
    {
        if ( -not (Test-Path $fullRequestResponseLoggingDirectory))
        {
            Write-Log "    Configured RequestResponseLogging Folder '$fullRequestResponseLoggingDirectory' not found." -Level INF
            New-Item -ItemType Directory -Path $fullRequestResponseLoggingDirectory | Out-Null
            Write-Log "    Configured RequestResponseLogging Folder '$fullRequestResponseLoggingDirectory' created." -Level INF
        }
        else {
            Write-Log "    Configured RequestResponseLogging Folder '$fullRequestResponseLoggingDirectory' found." -Level INF
        }
    }
    else
    {
        Write-Log "    RequestResponseLogging disabled, skipped checking." -Level INF
    }

    # file log
    $fileLogEnabled = Get-NestedJSONProperty -Object $config -Path "FileLogEnabled"
    $fileLogDirectory = Get-NestedJSONProperty -Object $config -Path "FileLogLogDirectory"
    if($fileLogEnabled)
    {
        if ( -not (Test-Path $fileLogDirectory))
        {
            Write-Log "    Configured File Log Folder '$fileLogDirectory' not found." -Level INF
            New-Item -ItemType Directory -Path $fileLogDirectory | Out-Null
            Write-Log "    Configured RequestResponseLogging Folder '$fileLogDirectory' created." -Level INF
        }
        else
        {
            Write-Log "    Configured File Log Folder '$fileLogDirectory' found." -Level INF
        }
    }
    else {
        Write-Log "    FileLog disabled, skipped checking." -Level INF
    }

    Write-Log "Step 9 -> $Step9Label - done." -Level INF
}

function Start-Step10-Check-WorkerAccount
{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    Write-Log "Step 10 -> $Step10Label ..." -Level INF
    Write-Log "    This step validates the Worker Account credentials and ensures it is a member of required groups: Administrators, Royal Server Users, Royal Server Gateway Users, and Royal Server Administrators." -Level DBG
    Write-Log "    The Worker Account credentials are encrypted in the configuration file." -Level INF

    # When -Force is specified, skip Worker Account configuration (keep existing configuration)
    if ($Force) {
        Write-Log "    Skipping Worker Account configuration (Force mode - keeping existing configuration)." -Level INF
        Write-Log "Step 10 -> $Step10Label - done." -Level INF
        return
    }

    # When -WhatIf is specified, skip Worker Account configuration (preview mode - no credential collection)
    if ($WhatIfPreference) {
        Write-Log "    Skipping Worker Account configuration (WhatIf mode - no changes will be made)." -Level INF
        Write-Log "Step 10 -> $Step10Label - done." -Level INF
        return
    }

    $configureWorkerAccount = Confirm-UserAction -Message "Do you want to configure a different Worker Account ?"

    if (-not $configureWorkerAccount) {
        Write-Log "    Skipping Worker Account configuration." -Level INF
        Write-Log "    Please configure the Worker Account manually using the Royal Server Configuration Tool." -Level WRN
        Write-Log "Step 10 -> $Step10Label - done." -Level INF
        return
    }

    # Get domain information to provide context-appropriate prompt
    $domainInfo = Get-DomainInfo

    # Ask for the worker account username with context-appropriate prompt
    if ($domainInfo.IsDomainJoined) {
        $workerUsername = Read-Host "Enter the Worker Account username (e.g. $($domainInfo.DomainName)\username)"
    } else {
        $workerUsername = Read-Host "Enter the Worker Account username (e.g. .\localuser or $env:COMPUTERNAME\localuser)"
    }

    if ([string]::IsNullOrWhiteSpace($workerUsername)) {
        Write-Log "    No username provided. Skipping Worker Account configuration." -Level WRN
        Write-Log "    Configure the Worker Account manually using the Royal Server Configuration Tool." -Level WRN
        Write-Log "Step 10 -> $Step10Label - done." -Level INF
        return
    }

    # Ask for the worker account password (for validation purposes)
    $workerPassword = Read-Host "Enter the Worker Account Password" -AsSecureString

    # Validate credentials
    Write-Log "    Validating Worker Account Credentials..." -Level INF
    try {
        $credential = New-Object System.Management.Automation.PSCredential($workerUsername, $workerPassword)
        $networkCredential = $credential.GetNetworkCredential()

        # Try to validate the credentials
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement

        $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $username = $networkCredential.UserName
        $domain = $networkCredential.Domain

        # If domain is specified and not local, use domain context
        if ($domain -and $domain -ne "." -and $domain -ne $env:COMPUTERNAME) {
            $contextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
            $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType, $domain)
        } else {
            $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($contextType)
            $username = $networkCredential.UserName
        }

        $valid = $context.ValidateCredentials($username, $networkCredential.Password)
        if (-not $valid) {
            Write-Log "    Invalid credentials provided. Please verify and try again." -Level ERR
            Write-Log "    Please configure the Worker Account manually using the Royal Server Configuration Tool." -Level WRN
            Write-Log "Step 10 -> $Step10Label - done." -Level INF
            return
        }
        Write-Log "    Worker Account Credentials validated successfully." -Level INF
    }
    catch {
        Write-Log "    Could not validate credentials: $($_.Exception.Message)" -Level WRN
        Write-Log "    Continuing with group membership configuration..." -Level INF
    }

    # Groups the worker account needs to be a member of
    $requiredGroups = @(
        "Administrators",
        "Royal Server Users",
        "Royal Server Gateway Users",
        "Royal Server Administrators"
    )

    # Get the SID of the worker account for reliable membership checks
    $workerSid = Get-AccountSid -AccountName $workerUsername
    if (-not $workerSid) {
        Write-Log "    Could not resolve SID for '$workerUsername'. Cannot check group memberships." -Level ERR
        Write-Log "Step 10 -> $Step10Label - done." -Level INF
        return
    }
    Write-Log "    Resolved SID for '$workerUsername': $workerSid" -Level DBG

    foreach ($groupName in $requiredGroups) {
        try {
            $group = [ADSI]"WinNT://./$groupName,group"

            if (-not $group.Path) {
                New-LocalGroup -Name $groupName
                Write-Log "   Local Windows Group $groupName was created."
            }

            # Check if user is already a member using SID comparison
            $isMember = Test-GroupMembershipBySid -GroupName $groupName -AccountSid $workerSid

            if ($isMember) {
                Write-Log "    '$workerUsername' is already a member of '$groupName'." -Level INF
            } else {
                if ($PSCmdlet.ShouldProcess("$workerUsername", "Add to group '$groupName'")) {
                    Write-Log "    Adding '$workerUsername' to '$groupName'..." -Level INF
                    try {
                        $adsiPath = Get-AdsiPath -AccountName $workerUsername
                        $group.Add($adsiPath)
                        Write-Log "    Successfully added '$workerUsername' to '$groupName'." -Level INF
                    }
                    catch {
                        Write-Log "    Failed to add '$workerUsername' to '$groupName': $($_.Exception.Message)" -Level ERR
                    }
                }
            }
        }
        catch {
            Write-Log "    Error processing group '$groupName': $($_.Exception.Message)" -Level ERR
        }
    }

    Write-Log "Step 10 -> $Step10Label - done." -Level INF
    return $credential
}

function Start-Step11-Start-RoyalServerService
{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [PSCredential]$WorkerCredential
    )
    Write-Log "Step 11 -> $Step11Label ..." -Level INF
    Write-Log "    This step starts the Royal Server Windows service, waits for it to initialize, and verifies it responds correctly on the status endpoint (HTTP 200)." -Level DBG

    $serviceName = "RoyalServer"

    try {
        $service = Get-Service -Name $serviceName -ErrorAction Stop

        if ($service.Status -eq "Running") {
            Write-Log "    Royal Server service is already running." -Level INF
        } else {
            if ($PSCmdlet.ShouldProcess("RoyalServer service", "Start")) {
                Write-Log "    Starting Royal Server service..." -Level INF
                Start-Service -Name $serviceName -ErrorAction Stop
                Write-Log "    Service start command issued." -Level INF

                # Wait for the service to start (15 seconds)
                Write-Host "Waiting for service to start " -NoNewline
                for ($i = 0; $i -lt 15; $i++) {
                    Start-Sleep -Seconds 1
                    Write-Host "." -NoNewline
                }
                Write-Host ""
            } else {
                Write-Log "Step 11 -> $Step11Label - done." -Level INF
                return
            }
        }

        # Refresh service status
        $service = Get-Service -Name $serviceName
        if ($service.Status -ne "Running") {
            Write-Log "    Royal Server service is not running after 10 seconds. Status: $($service.Status)" -Level ERR
            Write-Log "Step 11 -> $Step11Label - done." -Level INF
            return
        }
        
        
        Write-Log "    Royal Server service is running" -Level INF

        # check status page if we have $WorkerCredential
        $configPath = "$LocalPath\appsettings.json"
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $ipAddress = Get-NestedJSONProperty -Object $config -Path "IPAddress"
        $port = Get-NestedJSONProperty -Object $config -Path "Port"
        # If IP is 0.0.0.0 or ::, use localhost for the check
        if ($ipAddress -eq "0.0.0.0" -or $ipAddress -eq "::") {
            $ipAddress = "localhost"
        }

        $statusUrl = "https://${ipAddress}:${port}/status/get"

        if($WorkerCredential)
        {
            # Get IP and port from configuration
            if ([string]::IsNullOrWhiteSpace($ipAddress) -or [string]::IsNullOrWhiteSpace($port)) {
                Write-Log "    Could not read IP address or port from configuration." -Level WRN
                Write-Log "Step 11 -> $Step11Label - done." -Level INF
                return
            }

            Write-Log "    Checking Royal Server status at: $statusUrl" -Level INF

            try {
                # Build request parameters
                $requestParams = @{
                    Uri         = $statusUrl
                    Method      = 'Get'
                    TimeoutSec  = 10
                    ErrorAction = 'Stop'
                }

                # Add credential if provided
                if ($WorkerCredential) {
                    $requestParams.Credential = $WorkerCredential
                }

                # Ignore certificate errors for self-signed certificates
                if ($PSVersionTable.PSVersion.Major -ge 6) {
                    # PowerShell Core
                    $requestParams.SkipCertificateCheck = $true
                    $response = Invoke-WebRequest @requestParams
                } else {
                    # Windows PowerShell - need to bypass certificate validation
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
                    $response = Invoke-WebRequest @requestParams
                    [System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
                }

                if ($response.StatusCode -eq 200) {
                    Write-Log "    Royal Server is responding correctly (HTTP 200)." -Level INF
                } else {
                    Write-Log "    Royal Server returned unexpected status code: $($response.StatusCode)" -Level WRN
                }
            }
            catch {
                Write-Log "    Could not reach Royal Server status endpoint: $($_.Exception.Message)" -Level WRN
                Write-Log "    Please verify the service is running and the configuration is correct." -Level WRN
            }
        }
        else {
            Write-Log "    Royal Server Status cannot be checked since the Worker Account was not specified interactively." -Level WRN
            Write-Log "    $ArrowDown Check manually at $statusUrl" -Level WRN
        }
    }
    catch {
        Write-Log "    Error managing Royal Server service: $($_.Exception.Message)" -Level ERR
    }

    Write-Log "Step 11 -> $Step11Label - done." -Level INF
}

#------------------------------------------------------------
#endregion [ Step Functions ]
#------------------------------------------------------------

#------------------------------------------------------------
#region [ Main Execution ]
#------------------------------------------------------------

# Start transcript logging
$TranscriptPath = "$env:TEMP\RoyalServer-Installation-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
Start-Transcript -Path $TranscriptPath -ErrorAction SilentlyContinue | Out-Null
Write-Log "Transcript logging started: $TranscriptPath" -Level INF

Write-Log ""
Write-Log "This script installs Royal Server at '$($env:Computername)' based on source server '$SourceServer'." -Level INF
Write-Log "Copying Royal Server configuration from $SourceServer" -Level INF
Write-Log ""
if ($WhatIfPreference) {
    Write-Log "WhatIf mode is active. No changes will be made to the system." -Level INF
}

# Execute all steps
$preCheckResult = Start-Step0-PreCheck
if ($preCheckResult -ne 0) {
    Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
    exit $preCheckResult
}
Start-Step1-Install-RoyalServer
Start-Step2-Copy-RoyalServerLicenses
Start-Step3-Copy-RoyalServerConfiguration
Start-Step4-Copy-RoyalServerDatabase
Start-Step5-Copy-DocumentStore
Start-Step6-Install-RoyalServerCertificate
Start-Step7-Update-IpConfigurations
Start-Step8-Compare-GroupMemberships
Start-Step9-Check-ConfiguredFilePaths
$workerCredential = Start-Step10-Check-WorkerAccount

# Only pass WorkerCredential to Step 11 if it was configured.
# Step 10 returns $null when user skips or provides no username.
# Passing $null to a [PSCredential] parameter causes a type transformation error,
# so we use splatting to conditionally include the parameter.
$step11Params = @{}
if ($workerCredential) {
    $step11Params['WorkerCredential'] = $workerCredential
}
Start-Step11-Start-RoyalServerService @step11Params
Write-Log "Configuring local Royal Server - done" -Level INF

# Cleanup: Disconnect from remote share
net use $RemoteProgramData /delete 2>&1 | Out-Null

# Stop transcript logging
Stop-Transcript -ErrorAction SilentlyContinue | Out-Null
Write-Host "Transcript saved to: $TranscriptPath" -ForegroundColor Green

exit 0

#------------------------------------------------------------
#endregion [ Main Execution ]
#------------------------------------------------------------
