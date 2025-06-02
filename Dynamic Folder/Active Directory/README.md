# Table of Contents

- [Active Directory (Python).rdfx](#toc-Active-Directory-Python-rdfx)
- [AD Servers (Windows PowerShell).rdfx](#toc-AD-Servers-Windows-PowerShell-rdfx)
- [Basic Active Directory (Windows PowerShell).rdfx](#toc-Basic-Active-Directory-Windows-PowerShell-rdfx)

# <a name="toc-Active-Directory-Python-rdfx"></a> Active Directory (Python).rdfx

This Dynamic Folder sample allows you to import connections from Active Directory or any other LDAP-based directory.

Source files:

- [`Active Directory (Python).rdfx`](./Active%20Directory%20%28Python%29.rdfx)
- [`Active Directory (Python).script.py`](./Active%20Directory%20%28Python%29.script.py)
- [`Active Directory (Python).dynamicCredential.json`](./Active%20Directory%20%28Python%29.dynamicCredential.json)

## **Active Directory/LDAP Dynamic Folder sample**

**Version**: 1.0

**Author**: Royal Applications

This Dynamic Folder sample allows you to import connections from Active Directory or any other LDAP-based directory. It scans a configurable domain controller/LDAP server for computer objects and stores them in folders mimicking the OU structure of the directory. Based on the operating system of the computer object, either a Remote Desktop (Windows), a VNC (macOS) or an SSH (Linux) connection will be created. The "Custom Properties" section contains configuration parameters which must be populated before reloading the dynamic folder. Please also ensure that valid credentials for accessing the specified domain controller/LDAP server are configured in the "Credentials" section.

### **Requirements**

- Python Module: python-ldap

### **Setup**

- Specify credentials for accessing the domain controller/LDAP server in the "Credentials" section.
- Specify the domain controller/LDAP server in the "DC/LDAP Server" field of the "Custom Properties" section. This can either be a fully qualified domain name or an IP address. (Examples: "mydomain.local", "mydomaincontroller.mydomain.local", "192.168.0.1")
- Specify the base search path in the "Search Base" field of the "Custom Properties" section. (Example: "DC=mydomain,DC=local")

# <a name="toc-AD-Servers-Windows-PowerShell-rdfx"></a> AD Servers (Windows PowerShell).rdfx

This script allows you to query Active Directory to add computers from your Active Directory environment to RoyalTS.

Source files:

- [`AD Servers (Windows PowerShell).rdfx`](./AD%20Servers%20%28Windows%20PowerShell%29.rdfx)
- [`AD Servers (Windows PowerShell).script.ps1`](./AD%20Servers%20%28Windows%20PowerShell%29.script.ps1)

This script requires Windows PowerShell 4.x/5.x as well as the Active Directory 

Powershell Cmdlets.

This script allows you to query Active Directory to add computers from your Active Directory environment to RoyalTS.

To use this application, update the Custom Property ConfigFileName with the name of the configuration file for the dynamic folder.  This allows you to configure multiple dynamic folders using the same script without having to update the Custom Properties multiple times - the only time will be to set the setting file name.  If this field is not updated, the setting file will be set as Settings.xml.

Upon launching the form the first time, you are prompted to fill in a few settings.

The first setting is the domain name.  After you type in the domain name, the ldap dc path and Primary Domain Controller Emulator will autopopulate the DC Root and DC fields.  

The next field to fill in is the Connection Type dropdown.  This list contains all of the valid connection types the script is able to connect.  Depending on what option is selected other options will appear below the dropdown.  These settings include if the connection should use Cim sessions, what port number to use, and if the connection should be a admin/console connection.

The next field to fill in is the Credential Name.  This is the name of the credential in RoyalTS to have the computers open up with.  If you wish to set the credentials at the Dynamic Folder level in the same way of typical folders, you can leave this field blank and all the connections will be set to auto inherit their credentials from the Dynamic Folder.

SearchBase takes in the OU Path that the computers should be located in.  You can populate this field by clicking on the button to the right of the text box.  This button will load a GUI to select the correct OU.

SearchScope is how to search under the selected OU entered in SearchBase.  The three options under here are:

1. Base - only computers contained in the selected OU are listed
2. SubTree - all computers in all of the OUs under the selected OU are listed
3. OneLevel - all computers in the OUs one level under the selcted OU are listed

	

The filter field allows for adding in filters which are compatible with the PowerShell AD CMDLTS.  By default the filter is \* which will return all comptuers.  Example filters are below.

1. name -like 'test\*'
2. name -eq 'testpd09'

	

After your settings are entered, click Submit to save the data.

Every time you run the script to enumerate the computers, the Royal TS Dynamic Folder Configurator dialog will appear.  If the mouse is not moved over the screen within five seconds, the dialog assumes no data needs to be modified for the filter and the current selected filter is accepted.  

If the configuration file is missing and cannot be loaded by the script, then the dialog will not automatically close as these settings are required to produce a list of computers.

Configuration Walkthrough Video: [https://youtu.be/wMnqSQd1tYU](https://youtu.be/wMnqSQd1tYU)

Version: 1.1

Author: Paul DeArment Jr

Twitter: pdearmen

Github: https://github.com/armentpau

# <a name="toc-Basic-Active-Directory-Windows-PowerShell-rdfx"></a> Basic Active Directory (Windows PowerShell).rdfx

In this example the Get-ADComputer commandlet is used to retrieve information from the Active Directory and shows all found computer objects in a tree structure mimicking the OU structure in the Active Directory.

Source files:

- [`Basic Active Directory (Windows PowerShell).rdfx`](./Basic%20Active%20Directory%20%28Windows%20PowerShell%29.rdfx)
- [`Basic Active Directory (Windows PowerShell).script.ps1`](./Basic%20Active%20Directory%20%28Windows%20PowerShell%29.script.ps1)

Dynamic Folder for Basic Active Directory Synchronization

Version: 1.0

Author: Paul DeArment, Royal Applications

This is a very basic dynamic folder example for Windows using PowerShell. In this example the Get-ADComputer commandlet is used to retrieve information from the Active Directory and shows all found computer objects in a tree structure mimicking the OU structure in the Active Directory.

Special thanks to Paul DeArment from RandomizedHarmony for the contribution. You can also watch a YouTube video about this script here:

[https://www.youtube.com/watch?v=pKurlGhMfoQ&feature=youtu.be](https://www.youtube.com/watch?v=pKurlGhMfoQ&amp;feature=youtu.be)

The following Custom Properties can be configured:

Get-ADComputer Paramater:

SearchBase:

Specifies an Active Directory path to search under.

Example: ou=Enterprise Servers,dc=company,dc=pri

Filter:

Specifies a query string that retrieves Active Directory objects.

Example 1: \*

Example 2: Name -like "Computer01\*"

SearchScope:

Specifies the scope of an Active Directory search. The acceptable values for this parameter are:

- Base or 0
- OneLevel or 1
- Subtree or 2

	

See also: [https://docs.microsoft.com/en-us/powershell/module/addsadministration/get-adcomputer?view=win10-ps](https://docs.microsoft.com/en-us/powershell/module/addsadministration/get-adcomputer?view=win10-ps)

Connection Object Configuration:

Connection Type:

Specifies which connection type Royal TS should create for the found Actvie Directory computer object.

Example 1: RemoteDesktopConnection

Example 2: TerminalConnection

Credential Name:

Specifies the name of the credential for the connection object. If you specify "?" (without the quotes), Royal TS will prompt for the credential.

Extending the Script:

You can extend the script to inlcude more configuration settings or use a different credential mode. Feel free to adapt this dynamic folder, extend it, include additional custom properties and documentation, upload it to our github repository.

See also: [https://www.royalapplications.com/go/kb-all-royaljson](https://www.royalapplications.com/go/kb-all-royaljson)

