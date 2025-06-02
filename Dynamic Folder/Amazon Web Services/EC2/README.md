# Table of Contents

- [AWS EC2 (Python).rdfx](#toc-AWS-EC2-Python-rdfx)
- [AWS EC2 SSM (Python).rdfx](#toc-AWS-EC2-SSM-Python-rdfx)

# <a name="toc-AWS-EC2-Python-rdfx"></a> AWS EC2 (Python).rdfx

This Dynamic Folder sample for AWS EC2 supports grabbing all EC2 instances of a specified region.

Source files:

- [`AWS EC2 (Python).rdfx`](./AWS%20EC2%20%28Python%29.rdfx)
- [`AWS EC2 (Python).script.py`](./AWS%20EC2%20%28Python%29.script.py)
- [`AWS EC2 (Python).dynamicCredential.json`](./AWS%20EC2%20%28Python%29.dynamicCredential.json)

## **Dynamic Folder sample for Amazon Web Services (AWS) EC2**

**Version**: 1.0.1

**Author**: Royal Applications

This Dynamic Folder sample for AWS EC2 supports grabbing all EC2 instances of a specified region.

### **Prerequisites**

- AWS Command Line Interface (CLI) needs to be installed and configured.

### **Setup**

- Enter the region that you want to grab instances from in the "Region" field in the "Custom Properties" section or leave it as an empty string if you configured the AWS CLI with a default region.

### **Notes**

- While the provided script sets the username of created connections, the password will always be empty. There are multiple different ways to solve this. For instance, you could assign a credential to this dynamic folder and change the script to reference credentials from parent folder. Alternatively, you may also just use "Connect with Options - Prompt for Credentials" when establishing a connection.

# <a name="toc-AWS-EC2-SSM-Python-rdfx"></a> AWS EC2 SSM (Python).rdfx

This Dynamic Folder sample for AWS SSM EC2 supports grabbing all EC2 instances of a specified region managed by AWS Systems Manager.

Source files:

- [`AWS EC2 SSM (Python).rdfx`](./AWS%20EC2%20SSM%20%28Python%29.rdfx)
- [`AWS EC2 SSM (Python).script.py`](./AWS%20EC2%20SSM%20%28Python%29.script.py)

## **Dynamic Folder sample for Amazon Web Services (AWS) EC2 managed by SSM**

**Version**: 1.0.0

**Author**: Chrysostomos Galatoulas

This Dynamic Folder sample for AWS EC2 SSM supports grabbing all EC2 instances of a specified region managed by SSM. The script creates terminal connections with custom commands which is a feature only Royal TSX (for macOS) supports at the moment. That means this script currently only works on macOS and does NOT support Windows.

### **Prerequisites**

- AWS Command Line Interface (CLI) needs to be installed and configured.

### **Setup**

- Enter the region that you want to grab instances from in the "Region" field in the "Custom Properties" section or leave it as an empty string if you configured the AWS CLI with a default region.

### **Notes**

- You can append the --profile option on AWS cli commands to use a configured profile instead of a default.

