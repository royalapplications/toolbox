# <a name="toc-VMware-Pull-PowerShell-rdfe"></a> VMware-Pull (PowerShell).rdfe

Imports Virtual Machines from VMware ESXi Hosts or vCenter Servers

Source files:

- [`VMware-Pull (PowerShell).rdfe`](./VMware-Pull%20%28PowerShell%29.rdfe)
- [`VMware-Pull (PowerShell).script.ps1`](./VMware-Pull%20%28PowerShell%29.script.ps1)
- [`VMware-Pull (PowerShell).dynamicCredential.json`](./VMware-Pull%20%28PowerShell%29.dynamicCredential.json)

VMware ESXi Host / vCenter Dynamic Folder Example

This Dynamic Folder pulls all of the VMware VMs from your VMware ESXi Hosts or VMware vCenter environment and puts them into the appropriate DataCenter/Cluster folder.

Requirements:

PowerShell 5.1 or higher on Windows

PowerShell 7.2.1 or higher on MacOS (Thanks @lemonmojo)

VMware.PowerCLI Module 12.4.0 or higher

Configure the Server URL Custom Property with a comma separated list of ESXi Hosts or vCenter servers.

Configure your credentials under the Credentials Tab or leave them blank.

