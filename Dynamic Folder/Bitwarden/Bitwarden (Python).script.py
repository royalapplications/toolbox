from __future__ import print_function
from sys import platform as _platform
from functools import partial

import sys
import json
import subprocess
import os

# Disable deprecation warnings for node version of bw client
os.environ["NODE_OPTIONS"] = (
    " --no-deprecation"
    if os.getenv("NODE_OPTIONS", "") == ""
    else os.getenv("NODE_OPTIONS") + " --no-deprecation"
)

is_unix = _platform.lower().startswith("darwin") or _platform.lower().startswith(
    "linux"
)
have_pyotp = False
current_server = ""

try:
    import pyotp

    have_pyotp = True
except:
    pass

try:
    # for Python2
    from Tkinter import *
except ImportError:
    # for Python3
    from tkinter import *


class TakeInput(object):
    def __init__(self, request_message):
        self.root = Tk()

        title = ""

        if request_message:
            title = request_message

            if title.endswith(":"):
                title = title[:-1]

        self.root.title(title)

        # Do not allow the user to resize the window
        self.root.resizable(False, False)

        self.string = ""

        self.frame = Frame(self.root)

        self.acceptInput(request_message)
        self.frame.pack(padx=17, pady=17)

    def acceptInput(self, request_message):
        r = self.frame

        icon = Label(r, text="", image="::tk::icons::question")
        icon.grid(row=0, column=0, rowspan=2, sticky="w")

        label = Label(r, text=request_message)
        label.grid(row=0, column=1, padx=(9, 0), sticky="nw")

        self.e = Entry(r, text="Name")
        self.e.grid(row=1, column=1, padx=(13, 0), sticky="nw")
        self.e.configure(width=27)
        self.e.after(1, lambda: self.e.focus_force())

        b = Button(r, text="        OK        ", command=self.gettext)
        b.grid(row=2, column=1, sticky="ne", pady=(10, 0))

        self.root.bind("<Return>", self.gettext)

    def gettext(self, event=None):
        self.string = self.e.get()
        self.root.destroy()

    def getString(self):
        return self.string

    def configureWindowGeometry(self):
        # Get the window size
        window_width = self.root.winfo_width()
        window_height = self.root.winfo_height()

        # Get the screen size
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()

        # Get the window position from the top dynamically as well as position from left or right as follows
        position_top = int((screen_height / 2) - (window_height / 2))
        position_right = int((screen_width / 2) - (window_width / 2))

        # Shift up by a couple of pixels to account for the title bar
        position_top -= 30

        # This will center the window
        self.root.geometry(
            str(window_width)
            + "x"
            + str(window_height)
            + "+"
            + str(position_right)
            + "+"
            + str(position_top)
        )

    def waitForInput(self):
        self.root.lift()

        # Ensure that layout is ready
        self.root.attributes("-topmost", True)
        self.root.after_idle(self.root.attributes, "-topmost", False)

        self.root.update_idletasks()
        self.configureWindowGeometry()

        self.root.mainloop()


def show_prompt(request_message):
    msg_box = TakeInput(request_message)

    # loop until the user makes a decision and the window is destroyed
    msg_box.waitForInput()

    return msg_box.getString()


def convert_notes_to_html(notes):
    if notes is None:
        return ""
    else:
        return (
            notes.replace("\r\n", "<br />")
            .replace("\r", "<br />")
            .replace("\n", "<br />")
        )


def get_custom_server(bw_path) -> str:
    cmd_config_server = [bw_path, "config", "server"]

    bw = subprocess.Popen(
        cmd_config_server,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        stdin=subprocess.PIPE,
    )

    out_buffer = ""

    while True:
        out = bw.stdout.read(1).decode("utf-8")

        out_buffer += out

        if out == "" and bw.poll() is not None:
            break

    exit_code = bw.wait()

    return out_buffer


def set_custom_server(bw_path, url):

    cmd_config_server = [bw_path, "config", "server", url]

    bw = subprocess.Popen(
        cmd_config_server,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        stdin=subprocess.PIPE,
    )

    out_buffer = ""

    while True:
        out = bw.stdout.read(1).decode("utf-8")

        out_buffer += out

        if out == "" and bw.poll() is not None:
            break

    exit_code = bw.wait()

    if "Saved setting" not in out_buffer or exit_code != 0:
        printError(f"Unable to set server to {url}")

        sys.exit(1)


def create_credential(item):
    item_id = item["id"]
    item_type = item["type"]
    item_name = item["name"]
    item_notes = convert_notes_to_html(item.get("notes", ""))
    item_favorite = item.get("favorite", False)

    item_login = item.get("login", None)

    item_username = ""
    item_password = ""
    item_url = ""

    if item_login is not None:
        item_username = item_login.get("username", "")
        item_password = item_login.get("password", "")

        item_uris = item_login.get("uris", None)

        if item_uris is not None:
            for item_uri in item_login.get("uris", None):
                item_url = item_uri.get("uri", "")

    item_fields = item.get("fields", None)

    item_custom_properties = []

    if item_type == 3:  # Card
        item_card = item.get("card", None)

        if item_card is not None:
            card_brand = item_card.get("brand", "Credit Card")
            card_cardholdername = item_card.get("cardholderName", None)
            card_code = item_card.get("code", None)
            card_expiration_month = item_card.get("expMonth", None)
            card_expiration_year = item_card.get("expYear", None)
            card_number = item_card.get("number", None)

            item_custom_properties.append({"Type": "Header", "Name": card_brand})

            if card_cardholdername is not None:
                item_custom_properties.append(
                    {"Type": "Text", "Name": "Cardholder", "Value": card_cardholdername}
                )

            if card_number is not None:
                item_custom_properties.append(
                    {"Type": "Text", "Name": "Card Number", "Value": card_number}
                )

            if card_expiration_month is not None:
                item_custom_properties.append(
                    {
                        "Type": "Text",
                        "Name": "Expiration Month",
                        "Value": card_expiration_month,
                    }
                )

            if card_expiration_year is not None:
                item_custom_properties.append(
                    {
                        "Type": "Text",
                        "Name": "Expiration Year",
                        "Value": card_expiration_year,
                    }
                )

            if card_code is not None:
                item_custom_properties.append(
                    {"Type": "Protected", "Name": "Security Code", "Value": card_code}
                )

    if item_fields is not None:
        for item_field in item_fields:
            item_field_type = item_field["type"]
            item_field_name = item_field.get("name", "")
            item_field_value = item_field.get("value", "")

            custom_property_type = "Text"

            if item_field_type == 1:
                custom_property_type = "Protected"
            elif item_field_type == 2:
                custom_property_type = "YesNo"
                item_field_value = bool(item_field_value)

            if item_field_name is None:
                item_field_name = ""

            if item_field_value is None:
                item_field_value = ""

            custom_property = {
                "Type": custom_property_type,
                "Name": item_field_name,
                "Value": item_field_value,
            }

            item_custom_properties.append(custom_property)

    credential = {
        "Type": "Credential",
        "ID": item_id,
        "Name": item_name,
        "Notes": item_notes,
        "Favorite": item_favorite,
        "Username": item_username,
        "Password": item_password,
        "URL": item_url,
        "CustomProperties": item_custom_properties,
    }

    return credential


def logout(bw_path):
    cmd_logout = [bw_path, "logout"]
    bw = subprocess.Popen(cmd_logout, stdout=subprocess.PIPE)
    bw.wait()


def get_entries(
    bw_server, bw_path, username, password, totp_key, client_id, client_secret
):

    if not username or not password:
        printError("Login failed. Please specify your username and password.")

        sys.exit(1)

    logout(bw_path)

    if bw_server:
        global current_server
        current_server = get_custom_server(bw_path)

        if bw_server not in current_server:
            set_custom_server(bw_path, bw_server)

    if client_id and client_secret:
        os.environ["BW_CLIENTID"] = client_id
        os.environ["BW_CLIENTSECRET"] = client_secret

        cmd_login_api_key = [bw_path, "login", "--apikey", "--raw"]

        bw = subprocess.Popen(
            cmd_login_api_key,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            stdin=subprocess.PIPE,
        )
        exit_code = bw.wait()

        if exit_code != 0:
            printError(
                "Login using API key failed, please verify your Client ID and Client Secret."
            )

            sys.exit(1)

        cmd_login = [bw_path, "unlock", password, "--raw"]
    else:
        cmd_login = [bw_path, "login", username, password, "--raw"]

    bw = subprocess.Popen(
        cmd_login,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        stdin=subprocess.PIPE,
    )

    out_buffer = ""

    send_two_step_code = False
    multiple_two_step_methods = False

    while True:
        out = bw.stdout.read(1).decode("utf-8")

        out_buffer += out

        if not send_two_step_code:
            if out_buffer == "? Two-step login code:":
                send_two_step_code = True

                sys.stdout.flush()

                if have_pyotp and totp_key:
                    mfa_code = pyotp.TOTP(totp_key).now()
                else:
                    mfa_code = show_prompt("Enter your Bitwarden two-step login code:")

                bw.stdin.write((mfa_code + "\n").encode("utf-8"))

                break
            elif out_buffer == "? Two-step login method:":
                multiple_two_step_methods = True

                sys.stdout.flush()

                break

        if out == "" and bw.poll() is not None:
            break

    if multiple_two_step_methods:
        printError(
            "Login failed. Multiple two-step login methods are enabled. This script only supports a single two-step login method."
        )

        sys.exit(1)

    (session_key, err) = bw.communicate()

    if send_two_step_code:
        session_key = session_key.decode("utf-8")
    else:
        session_key = out_buffer

    out_buffer_split = session_key.split("\n")

    if out_buffer_split is not None and len(out_buffer_split) >= 1:
        out_buffer_split = list(filter(None, out_buffer_split))

        last_line = out_buffer_split[len(out_buffer_split) - 1]

        session_key = last_line

    exit_code = bw.wait()

    if exit_code != 0:
        printError("Login failed, please verify your credentials.")

        sys.exit(1)

    cmd_sync = [bw_path, "sync", "--session", session_key]

    bw = subprocess.Popen(cmd_sync, stdout=subprocess.PIPE)
    bw.wait()

    cmd_list_items = [bw_path, "list", "items", "--session", session_key]

    bw = subprocess.Popen(cmd_list_items, stdout=subprocess.PIPE)
    (list_items_json, err) = bw.communicate()
    exit_code = bw.wait()

    if exit_code != 0:
        printError("Listing items failed.")

        sys.exit(1)

    list_items_response = json.loads(list_items_json)

    store_objects = []

    for item in list_items_response:
        cred = create_credential(item)

        store_objects.append(cred)

    store = {"Objects": store_objects}

    store_json = json.dumps(store)

    return store_json


bw_path_windows = r"$CustomProperty.BWPathWindows$"
bw_path_macOS = r"$CustomProperty.BWPathmacOS$"

bw_path = bw_path_macOS if is_unix else bw_path_windows
bw_path = os.path.expandvars(bw_path)

bw_server = r"$CustomProperty.BWServer$"
bw_user = r"$EffectiveUsername$"
bw_pass = r"$EffectivePassword$"
bw_totp_key = r"$CustomProperty.TOTPkey$"
bw_client_id = r"$CustomProperty.ClientID$"
bw_client_secret = r"$CustomProperty.ClientSecret$"

printError = partial(print, file=sys.stderr)  # python2 compatibility

print(
    get_entries(
        bw_server,
        bw_path,
        bw_user,
        bw_pass,
        bw_totp_key,
        bw_client_id,
        bw_client_secret,
    )
)

logout(bw_path)

if current_server != "":
    set_custom_server(bw_path, current_server)

