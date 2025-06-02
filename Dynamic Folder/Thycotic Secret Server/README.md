# <a name="toc-Thycotic-Secret-Server-PowerShell-rdfx"></a> Thycotic Secret Server (PowerShell).rdfx

This Dynamic Folder sample for Thycotic Secret Server supports Dynamic Credentials and Multi-Factor-Authentication (MFA).

Source files:

- [`Thycotic Secret Server (PowerShell).rdfx`](./Thycotic%20Secret%20Server%20%28PowerShell%29.rdfx)
- [`Thycotic Secret Server (PowerShell).script.ps1`](./Thycotic%20Secret%20Server%20%28PowerShell%29.script.ps1)
- [`Thycotic Secret Server (PowerShell).dynamicCredential.ps1`](./Thycotic%20Secret%20Server%20%28PowerShell%29.dynamicCredential.ps1)

## **Dynamic Folder sample for Secret Server**

**Version**: 1.0.2

**Author**: Royal Applications

This Dynamic Folder sample for Thycotic Secret Server supports Dynamic Credentials and Multi-Factor-Authentication (MFA).

### **Requirements**

- PowerShell 6.0 or higher

### **Setup**

- Enter your "Server URL" in the "Custom Properties" section.
- Enter or assign your Secret Server credentials.
- If MFA is required by your server/user, enable it by setting "-requiresMFA" to "$true" instead of "$false" in the last line of both scripts.

