import json
import os
import subprocess
import sys

empty_vaults_filter = 'empty_vaults_filter'
op_path_windows = r"$CustomProperty.OPPathWindows$"
op_path_macOS = r"$CustomProperty.OPPathmacOS$"
filter_account = r"$CustomProperty.Account$"
filter_vaults = r"$CustomProperty.Vaults$"
item_id = r"$DynamicCredential.EffectiveID$"

class RoyalUtils:
  @staticmethod
  def is_macOS():
    return sys.platform.lower().startswith("darwin")

  @staticmethod
  def exit_with_error(message, exception=None):
    exception_message = str(exception) if exception else "N/A"
    print(message + ': ' + exception_message, file=sys.stderr)
    sys.exit(1)

  @staticmethod
  def to_json(obj, pretty=False):
    return json.dumps(obj, indent=4) if pretty else json.dumps(obj)

  @staticmethod
  def decode_to_utf8_string(potential_bytes):
    if isinstance(potential_bytes, str):
      return potential_bytes
    else:
      return potential_bytes.decode("utf-8")

class OnePassword:
  op_path = ""
  account = ""
  vaults = []
  unknown_error_string = "An unknown error occurred."

  def __init__(self, op_path, account="", vaults=[]):
    self.op_path = op_path
    self.account = account
    self.vaults = ''.join(vaults.split()).split(',')

    # add dummy list item if no filter is specified
    if not self.vaults:
      self.vaults.append(empty_vaults_filter)

  def get_items(self):
    items = []
    failed = False

    for vault in self.vaults:
      cmd_list_items = [
        self.op_path,
        "item", "list",
        "--format=json",
      ]

      if self.account:
        cmd_list_items.append("--account")
        cmd_list_items.append(self.account)

      if vault != empty_vaults_filter:
        cmd_list_items.append("--vault")
        cmd_list_items.append(vault)

      env = os.environ.copy()
      env["OBJC_DEBUG_MISSING_POOLS"] = "NO"
      op = subprocess.Popen(cmd_list_items, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
      (output, err) = op.communicate()
      exit_code = op.wait()
      success = exit_code == 0

      if success:
        items.extend(json.loads(RoyalUtils.decode_to_utf8_string(output)))
      else:
        failed = True
    
    if not failed:
      return items
    else:
      if not err:
        err = self.unknown_error_string
      else:
        err = RoyalUtils.decode_to_utf8_string(err)
    
      raise Exception(err)

  def get_item_details(self, item_id):
    cmd_get_item = [
      self.op_path,
      "item", "get", item_id,
      "--format=json",
    ]

    if self.account:
      cmd_get_item.append("--account")
      cmd_get_item.append(self.account)

    env = os.environ.copy()
    env["OBJC_DEBUG_MISSING_POOLS"] = "NO"
    op = subprocess.Popen(cmd_get_item, stdout=subprocess.PIPE, stderr=subprocess.PIPE, env=env)
    (output, err) = op.communicate()
    exit_code = op.wait()

    success = exit_code == 0

    if success:
      output = RoyalUtils.decode_to_utf8_string(output)
      item = json.loads(output)
    
      return item
    else:
      if not err:
        err = self.unknown_error_string
      else:
        err = RoyalUtils.decode_to_utf8_string(err)
      
      raise Exception(err)

class Converter:
  @staticmethod
  def convert_items(items):
    objects = []

    for item in items:
      id = item.get("id", "")
      title = item.get("title", "N/A")
      
      primary_url = ""
      if "urls" in item:
        for url in item["urls"]:
          if url.get("primary", None):
            primary_url = url["href"]

      vault_name = ""
      if item.get("vault", None):
        vault_name = item["vault"].get("name", "")

      cred_type = "DynamicCredential"

      cred = {
        "Type": cred_type,
        "ID": id,
        "Name": title,
        "Path": vault_name
      }

      if primary_url != "":
        cred["URL"] = primary_url
      
      objects.append(cred)

    objects = sorted(objects, key = lambda i: (i["Path"], i["Name"]))

    store = {
      "Objects": objects
    }

    return store
  
  @staticmethod
  def convert_item(item_details):
    username = None
    password = None
    private_key = None

    fields = item_details.get("fields")

    for field in fields:
      field_id = field.get("id", None)
      field_label = field.get("label", None)
      field_value = field.get("value", None)

      if field_id == "username" or field_label.casefold() == "username":
        username = field_value
      elif field_id == "password" or field_label.casefold() == "password":
        password = field_value
      elif field_id == "private_key" or field_label.casefold() == "private key":
        private_key = field_value

    cred = { }

    if username is not None:
      cred["Username"] = username

    if password is not None:
      cred["Password"] = password

    if private_key is not None:
      cred["KeyFileContent"] = private_key

    return cred

class Coordinator:
  op_path = ""
  account = ""
  vaults = ""

  error_message_get_items = "Error while getting items"
  error_message_get_item_details = "Error while getting item details"

  def __init__(self, op_path_windows, op_path_macOS, account, vaults):
    self.op_path = op_path_macOS if RoyalUtils.is_macOS() else op_path_windows
    self.account = account
    self.vaults = vaults
    
  def get_items(self):
    op = OnePassword(self.op_path, self.account, self.vaults)
    items = None

    try:
      items = op.get_items()
    except Exception as e:
      RoyalUtils.exit_with_error(self.error_message_get_items, e)
    
    items_details = [ ]

    store = Converter.convert_items(items)
    store_json = RoyalUtils.to_json(store, True)

    print(store_json)
  
  def get_item_details(self, item_id):
    op = OnePassword(self.op_path, self.account, self.vaults)
    item_details = None

    try:
      item_details = op.get_item_details(item_id)
    except Exception as e:
      RoyalUtils.exit_with_error(self.error_message_get_item_details, e)

    store = Converter.convert_item(item_details)
    store_json = RoyalUtils.to_json(store, True)

    print(store_json)

coordinator = Coordinator(op_path_windows, op_path_macOS, filter_account, filter_vaults)
#coordinator.get_items()
coordinator.get_item_details(item_id)