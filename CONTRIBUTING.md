## Contributing

### New scripts

- **The right place**: The repository should stay clearly structured, to provide a good overview. Each script should have their own directory, containing all relevant files, like screenshots and documentation.
- **Permissions**: Make sure you are allowed to share the script with the public. Publish it under the same [license](LICENSE) of this repository. By comitting/posting pull requests, you agree with this.
- **Documentation**: Your shared script contains enough documentation/instructions that other users are able to easily understand the purpose and are able to use it without a lot of guesswork.
- **Stay clean**: Your code should be as clean, smart and understandable as possible. Prevent having any magic, encrypted or obfuscated code.

### Modifying existing scripts

- **Credits**: Please respect previous authors and leave them intact. If you feel you've done great enhancements to existing scripts, feel free to add yourself to the authors list.
- **Compatibility**: Don't forget about backwards-compatibility. Try not to break existing scripts. If you're doing changes regarding parameters, dependencies or any other major changes, please create a new script directory or new files within the same folder.

### Do not include or update generated files

When `.rdfe` or `.rdfx` files are added or updated under the `Dynamic Folder` directory, a tool runs to automatically generate or update files in this repo, e.g.:

- `Sample.script.autogen.EXT`: extracted source code from the `Script` entry of the `.rdfe`/`.rdfx` file;
   
- `Sample.dyncred-script.autogen.EXT`: extracted source code from the `DynamicCredentialScript` entry of the `.rdfe`/`.rdfx` file;

- `README.md`: generated documentation, extracted from the `Description` and `Notes` entries of all `.rdfe`/`.rdfx` files within one directory.

Avoid editing any `.autogen.*` and `README.md` files manually. Such changes from your fork will be lost once a pull request is accepted and merged. The repo tool runs at that point, re-generating all these files and overwriting your changes.

---

Okay with the few points above? Great! Go ahead and create a pull request with your contribution. Thanks a lot! :-)
