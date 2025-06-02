# <a name="toc-Softlayer-Servers-Python-rdfx"></a> Softlayer Servers (Python).rdfx

This Dynamic Folder sample for IBM Softlayer supports grabbing all virtual servers of a specified datacenter.

Source files:

- [`Softlayer Servers (Python).rdfx`](./Softlayer%20Servers%20%28Python%29.rdfx)
- [`Softlayer Servers (Python).script.py`](./Softlayer%20Servers%20%28Python%29.script.py)
- [`Softlayer Servers (Python).dynamicCredential.json`](./Softlayer%20Servers%20%28Python%29.dynamicCredential.json)

## **Dynamic Folder sample for IBM Softlayer Virtual Server**

**Version**: 1.0

**Author**: Royal Applications, [Matt Warren](https://github.com/eightnoneone)

This Dynamic Folder sample for IBM Softlayer supports grabbing all virtual servers of a specified datacenter.

### **Prerequisites**

- Softlayer Command Line Interface (CLI) Python pip module needs to be installed and configured for your OS default Python.
[https://softlayer-api-python-client.readthedocs.io/en/latest/](https://softlayer-api-python-client.readthedocs.io/en/latest/)

### **Setup**

- Enter the datacenter that you want to grab instances from in the "Datacenter" field in the "Custom Properties" section or leave it as an empty string if you configured the SLCLI with a default datacenter.
- Depends on a SLCLI config file for username and password/key.

### **Notes**

- The provided script sets SSH connections to "Use credentials from parent folder" and sets RDP connections to "Specify a credential name" There are multiple different ways to manage credentials with Royal. Alternatively, you may also just use "Connect with Options - Prompt for Credentials" when establishing a connection.

