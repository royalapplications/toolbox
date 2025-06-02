import subprocess
import json

def get_instances(region = ""):
	cmd = "aws ec2 describe-instances --output json"

	if region != "":
		cmd += " --region " + region

	aws = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
	(response_json, err) = aws.communicate()
	exit_code = aws.wait()

	response = json.loads(response_json)

	connections = [ ]

	for reservation in response.get("Reservations", None):
		for instance in reservation.get("Instances", None):
			instance_id = instance.get("InstanceId", "")
			platform = instance.get("Platform", "")

			is_windows = platform.lower() == "windows"
			username = "Administrator" if is_windows else "ec2-user"

			public_ip_address = instance.get("PublicIpAddress", "")
			public_hostname = instance.get("PublicDnsName", "")

			private_ip_address = instance.get("PrivateIpAddress", "")
			private_hostname = instance.get("PrivateDnsName", "")

			tags = instance.get("Tags")
			name = instance_id

			if tags is not None:
				for tag in tags:
					if tag.get("Key", "").lower() == "name":
						tagValue = tag.get("Value", "")

						if tagValue.lower() != "":
							name = tagValue
						
						break

			computer_name = public_hostname

			if computer_name == "":
				computer_name = public_ip_address

			if computer_name == "":
				computer_name = private_hostname

			if computer_name == "":
				computer_name = private_ip_address

			connection = { }

			if not is_windows:
				connection["Type"] = "TerminalConnection"
				connection["TerminalConnectionType"] = "SSH"
			else:
				connection["Type"] = "RemoteDesktopConnection"

			connection["ID"] = instance_id
			connection["Name"] = name
			connection["ComputerName"] = computer_name
			connection["Username"] = username

			connections.append(connection)

	store = {
		"Objects": connections
	}

	store_json = json.dumps(store)

	return store_json

print(get_instances("$CustomProperty.Region$"))