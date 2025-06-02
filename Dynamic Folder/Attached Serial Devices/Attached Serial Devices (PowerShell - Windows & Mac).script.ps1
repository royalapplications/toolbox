# Royal TS Attached Serial Devices Dynamic Folder script
# version 2.3

$ErrorActionPreference = "STOP"

# Determine OS type based on version and platform
switch ($PSVersionTable.PSVersion.Major) {
  { $_ -le 5 } {
      $IsOSWindows = ([System.Environment]::OSVersion.Platform -eq "Win32NT")
      $IsOSMacOS = -not $IsOSWindows
  }
  default {
      $IsOSWindows = $IsWindows  # Utilize predefined variables for PowerShell 6.0+
      $IsOSMacOS = $IsMacOS
  }
}

# Set variables for com port speeds and frame settings
$comPortSpeeds = @($CustomProperty.PortSpeeds$)
$comPortFrameSettings = @($CustomProperty.FrameSettings$)

# Pulls serial device list per OS type.
if ($IsOSWindows){
    # Collect a list of avilable serial ports from WMI. See here for discussion: https://stackoverflow.com/questions/19840811/list-of-serialports-queried-using-wmi-differs-from-devicemanager
    $comPorts = Get-WmiObject -query 'SELECT * FROM Win32_PnPEntity WHERE ClassGuid="{4d36e978-e325-11ce-bfc1-08002be10318}"'
}
elseif ($IsOSMacOS){
    # Collect a list of available usb serial and modem devices for Mac OS
    $comPorts = @(Get-ChildItem -Path "/dev/tty.usbserial*" | Select-Object -ExpandProperty Name
    ; Get-ChildItem -Path "/dev/tty.usbmodem*" | Select-Object -ExpandProperty Name)
}
else {
    Write-Host "[ERROR] OS not detected. Halting" -ForegroundColor Red
    throw
}

$folders = @()
foreach ($comPort in $comPorts) {
  $connections = @()
  $comPortCaption = $comPort.Caption;
  if ($comPortCaption -match '.*\((COM\d+)\)') {
    $comPortDevice = $Matches[1]
  }
  elseif ($comPort -match '(usbserial.+)') {
    $comPortCaption = $comPort
    $comPortDevice = $Matches[1]
  }
  elseif ($comPort -match '(usbmodem.+)') {
    $comPortCaption = $comPort
    $comPortDevice = $Matches[1]
  }
  else {
    continue
  }
  foreach ($comPortSpeed in $comPortSpeeds) {
    foreach ($comPortFrameSetting in $comPortFrameSettings) {
      if ($comPortFrameSetting -match '^(\d)([NOEMSnoems])(\d)$') {
        [int]$comPortDataBits = $Matches[1]
        $comPortParityAlpha = $Matches[2].ToUpper()
        [int]$comPortStopBits = $Matches[3]
      }
      else {
        continue
      }
      if ($comPortParityAlpha -eq "N") {
        [int]$comPortParity = "0"
      }
      elseif ($comPortParityAlpha -eq "O") {
        [int]$comPortParity = "1"
      }
      elseif ($comPortParityAlpha -eq "E") {
        [int]$comPortParity = "2"
      }
      elseif ($comPortParityAlpha -eq "M") {
        [int]$comPortParity = "3"
      }
      elseif ($comPortParityAlpha -eq "S") {
        [int]$comPortParity = "4"
      }
      else {
        continue
      }
      $connectionProperties = New-Object PSCustomObject -Property @{
        "BaudRate" = $comPortSpeed;
        "DataBits" = $comPortDataBits;
        "Parity"   = $comPortParity;
        "StopBits" = $comPortStopBits;
      }
      $connection = New-Object PSCustomObject -Property @{
        "Type"                   = "TerminalConnection";
        "TerminalConnectionType" = "SerialPort";
        "Name"                   = "$comPortDevice $comPortSpeed $comPortFrameSetting";
        "SerialPortName"         = $comPortDevice;
        "Properties"             = $connectionProperties;
      }
      $connections += $connection
    }
  }
  $folder = New-Object PSCustomObject -Property @{
    "Type"    = "Folder";
    "Name"    = $comPortCaption;
    "Objects" = $connections;
  }
  $folders += $folder
}
@{ Objects = $folders } | ConvertTo-Json -Depth 5