import SoftLayer
import json


def get_instances(datacenter = ""):

    client = SoftLayer.Client()
    mgr = SoftLayer.VSManager(client)

    connections = [ ]

    object_mask = "mask[globalIdentifier,hostname,operatingSystemReferenceCode,primaryBackendIpAddress]"
    for instance in mgr.list_instances(datacenter=datacenter, mask=object_mask):

        instance_id = instance.get("globalIdentifier", "")
        is_windows = instance.get("operatingSystemReferenceCode").partition('_')[0] == "WIN"


#         public_ip_address = instance.get("PublicIpAddress", "")
#         public_hostname = instance.get("PublicDnsName", "")

        private_ip_address = instance.get("primaryBackendIpAddress", "")
        private_hostname = instance.get("hostname", "")
        name = private_hostname

# Fetching tags on each vs is very time consuming. 
#         tags = details.get("tagReferences")
#         tagstring = [ ]
#         for tag in tags:
#             tagstring.append(tag['tag'].get('name'))
#         notes = ' '.join(tagstring)
        

        computer_name = private_ip_address

        if computer_name == "":
            computer_name = public_ip_address

        connection = { }

        if not is_windows:
            connection["Type"] = "TerminalConnection"
            connection["TerminalConnectionType"] = "SSH"
            connection['CredentialsFromParent'] = True
        else:
            connection["Type"] = "RemoteDesktopConnection"
            connection['CredentialName'] = "AD_Crendentials"

        connection["ID"] = instance_id
        connection["Name"] = name
        connection["ComputerName"] = computer_name
#         connection['Notes'] = notes
        

        connections.append(connection)

    store = {
        "Objects": connections
    }

    store_json = json.dumps(store, indent=2)

    return store_json

print(get_instances("$CustomProperty.Datacenter$"))