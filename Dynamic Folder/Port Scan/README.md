# <a name="toc-Port-Scan-Python-rdfx"></a> Port Scan (Python).rdfx

This Dynamic Folder sample scans your main network interface's IP subnet for open ports.

Source files:

- [`Port Scan (Python).rdfx`](./Port%20Scan%20%28Python%29.rdfx)
- [`Port Scan (Python).script.py`](./Port%20Scan%20%28Python%29.script.py)
- [`Port Scan (Python).dynamicCredential.json`](./Port%20Scan%20%28Python%29.dynamicCredential.json)

## **Port Scan Dynamic Folder sample**

**Version**: 1.0

**Author**: Royal Applications

This Dynamic Folder sample scans your main network interface's IP subnet for open ports. The connection types/ports to scan can be configured in the "Custom Properties" section.

### **Note**

Port scans can take a very long time depending on your subnet size, the number of ports enabled for scanning and the configured connection timeout. Please be patient and/or adjust the configuration as needed.

### **Requirements**

- Python Module: netifaces

### **Setup**

- Enable or disable the connection types you want to be scanned in the "Custom Properties" section.
- Configure a timeout (in seconds) for each scanned port in the "Custom Properties" section.

