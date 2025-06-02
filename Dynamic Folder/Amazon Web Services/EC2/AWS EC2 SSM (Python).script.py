import subprocess
import json

def get_instances(region = ""):
	cmd = "aws ssm describe-instance-information --output json"

	if region != "":
		cmd += " --region " + region

	aws = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
	(response_json, err) = aws.communicate()
	exit_code = aws.wait()

	response = json.loads(response_json)

	connections = [ ]

	for instance in response.get("InstanceInformationList", None):
		instance_id = instance.get("InstanceId", "")
		platform = instance.get("PlatformType", "")

		is_windows = platform.lower() == "windows"

		computer_name = instance.get("ComputerName", "")
		private_ip_address = instance.get("IPAddress", "")

		name = instance_id

		connection = { }
		if not is_windows:
			connection["Type"] = "TerminalConnection"
			connection["TerminalConnectionType"] = "CustomTerminal"
		else:
			connection["Type"] = "RemoteDesktopConnection"

		connection["ID"] = instance_id
		connection["Name"] = computer_name
		connection["ComputerName"] = computer_name

		connection["CustomCommand"] = f"aws ssm start-session --target {instance_id}"		
		
		
		connection["Properties"] = {}
		connection["Properties"]["RunInsideLoginShell"] = True
		
		
		connections.append(connection)

	store = {
		"Objects": connections
	}

	store_json = json.dumps(store)

	return store_json
	
print(get_instances("$CustomProperty.Region$"))
