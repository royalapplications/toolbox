import boto3
import json
'''
- Tested on MacOS only, but with little modifications should work elsewhere. 
- Uses systems default Python as I failed to specify any other. A venv support for Royal TSX would be awesome.
- Make sure you have boto3 installed for default Python.
'''

class RoyalProvider:
    def __init__(self, region, tag):
        self.ec2 = boto3.client("ec2", region_name=region)
        self.tag = tag
        self.region = region
        self.instance_data = self.get_all_instances_in_region()

    def get_all_instances_in_region(self):
        response = self.ec2.describe_instances()
        instance_data = {}

        for reservation in response["Reservations"]:
            for instance in reservation["Instances"]:
                if len(instance["Tags"]) == 0:
                    try:
                        instance_data["NotTagged"].append(instance["InstanceId"])
                    except KeyError:
                        instance_data["NotTagged"] = [instance["InstanceId"]]
                else:
                    for tag in instance["Tags"]:
                        if tag["Key"] == self.tag:
                            try:
                                instance_data[tag["Value"]].append(
                                    instance["InstanceId"]
                                )
                            except KeyError:
                                instance_data[tag["Value"]] = [instance["InstanceId"]]
                            break
                    else:
                        try:
                            instance_data["NotTagged"].append(instance["InstanceId"])
                        except KeyError:
                            instance_data["NotTagged"] = [instance["InstanceId"]]
        return instance_data

    def get_royal_data(self):
        royal_json = {"Objects": []}
        for key, value in self.instance_data.items():
            objects = []
            for instance in value:
                instance_json = {
                    "Type": "TerminalConnection",
                    "Name": instance,
                    "TerminalConnectionType": "CustomTerminal",
                    "CustomCommand": "/usr/local/bin/mssh root@{0}".format(instance),
                }
                objects.append(instance_json)
            group_json = {
                "Type": "Folder",
                "Name": "TAG: " + key,
                "Desciption": "All EC2 instances grouped by Tag value by specified tag Name",
                "Notes": "",
                "ScriptInterpreter": "python",
                "Objects": objects,
            }
            royal_json["Objects"].append(group_json)

        return json.dumps(royal_json)


royal = RoyalProvider("eu-central-1", "aws:cloudformation:stack-name")
print(royal.get_royal_data())
