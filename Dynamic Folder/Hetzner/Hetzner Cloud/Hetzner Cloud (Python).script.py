import subprocess
import json
import os
import re
import sys

# log_error will write the error to the stderr, so that Royal TS will display it.


def log_error(err):
    print("error: {}".format(err.strip()), file=sys.stderr)
    exit(1)


def get_instances(api_key):
    os.environ["HCLOUD_TOKEN"] = api_key
    cmd = "hcloud"
    store = {
        "Objects": []
    }
    # get servers
    server_list_process = subprocess.Popen(
        "{} server list -o columns=id,name,ipv4 -o noheader".format(cmd), stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (stdout, stderr) = server_list_process.communicate()
    exit_code = server_list_process.wait()
    # check if hcloud returned a successful status code != 0
    if exit_code != 0:
        log_error("could not get server list: {}".format(stderr.decode()))
    # loop over the returned servers and build the royal ts JSON
    for line in stdout.decode().strip().splitlines():
        values = re.findall(r"[^ ]+", line)
        store["Objects"].append({
            "ID": values[0],
            "Name": values[1],
            "ComputerName": values[2],
            "Username": "root",
            "Type": "TerminalConnection",
            "TerminalConnectionType": "SSH",
            "CredentialsFromParent": True
        })
    return json.dumps(store)


print(get_instances("$CustomProperty.APIKey$"))
