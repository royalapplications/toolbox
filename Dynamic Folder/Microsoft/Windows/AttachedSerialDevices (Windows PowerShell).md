# Attached Serial Devices Dynamic Folder

This script utilizes PowerShell to generate a list of available serial devices, along with RTS Custom Properties defining speeds and framing settings, to generate a set of Terminal connections for each combination of port/speed/framing.

The resulting folder structure will look something like the following:

```
Attached Serial Devices
|-- USB Serial Device (COM12)
|   |-- COM12 9600 8N1
|   |-- COM12 9600 7E1
|   |-- COM12 19200 8N1
|   `-- COM12 19200 7E1
`-- USB-SERIAL CH340 (COM34)
    |-- COM34 9600 8N1
    |-- COM34 9600 7E1
    |-- COM34 19200 8N1
    `-- COM34 19200 7E1
```

## Requirements

This solution only works under Windows due to its use of WMI to identify available COM ports.

## Custom Properties

### Port Speeds

This field must contain comma-separated list of serial port speeds in numeric format.

* **Example 1**: `9600`
* **Example 2**: `9600,19200,115200`

### Frame Settings

This field must contain comma-separated list of serial port framing standards (8N1, 7E1, etc) in alphanumeric format, and each entry must be in double quotes.

* **Example 1**: `"8N1"`
* **Example 2**: `"8N1","7E1"`
