# <a name="toc-Wallix-Bastion-PowerShell-rdfx"></a> Wallix Bastion (PowerShell).rdfx

Imports servers SSH and RDP from Wallix Bastion

Source files:

- [`Wallix Bastion (PowerShell).rdfx`](./Wallix%20Bastion%20%28PowerShell%29.rdfx)
- [`Wallix Bastion (PowerShell).script.ps1`](./Wallix%20Bastion%20%28PowerShell%29.script.ps1)
- [`Wallix Bastion (PowerShell).dynamicCredential.ps1`](./Wallix%20Bastion%20%28PowerShell%29.dynamicCredential.ps1)

## 		Dynamic Folder for Wallix Bastion connections
	
Version: 1.0

This Dynamic Folder allows you to import SSH and RDP connections from a Wallix Bastion. It is then possible to connect more easily to a server through the Wallix Bastion, while avoiding the Bastion selection screen.

### 		Tested with
	
- Wallix Bastion 9.0 and PowerShell 5.1 on Windows

	
### 		Setup

- In the « Custom Properties »
    - set the hostname of Wallix Bastion
    - define if Wallix API use HTTPS or HTTP
    - set the Wallix Bastion’s fingerprint
- In the « Credentials »
    - Configure your credentials

	
### 		How it works
	
This script uses the Bastion API with HTTP/HTTPS to retrieve a list of all SSH and RDP connections. For the connection to a server, it uses the credentials assigned to the dynamic folder. It builds the servers list with the Wallix hostname as computer name and assigns dynamic credentials. If it's a Linux server, the Wallix Bastion fingerprint is also added. When connecting to a server via SSH or RDP, the dynamic credential script is called. It will use CustomField1, containing the concatenation of some Bastion information to generate the login allowing direct access to the server without having to go through the Bastion selection screen.

### 		Limitation
	
With PowerShell 5.1 it is not possible to bypass SSL certificate verification for HTTPS calls to the Wallix Bastion API. You must therefore have a valid certificate to use HTTPS.

