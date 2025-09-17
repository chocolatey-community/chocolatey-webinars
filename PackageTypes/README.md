# Unwrapping Chocolatey: Package Types

In our August 2025 webinar of Unwrapping Chocolatey we discussed various package types that you are able to create. We demonstrated live how to work with both remote and embedded installers, zips, just scripts, and meta (virtual) packages.

## Key Takeaways

- Identify what you are attempting to do: Execute an installer, extract an archive, or copy some data, etc.
- Use https://docs.chocolatey.org/en-us/create/functions/#mainContent to identify helper functions which make tasks easier
- Ask questions! Run `choco support` to reach out to us if you have commercial support. Join our [Discord](https://ch0.co/community) if you don't have commercial support but require community assistance.

### Working with installers

Executing an installer _requires_ just two things:

- The installer itself
- The silent arguments to pass to the installer

See the `Installers` folder for examples.

### Working with archive files

Similar to installers, working with archive files (zip, 7z, etc) _requires_ only two things:

- The archive file
- The destination

With those two things known, or easily acquired, creating a package is simply a matter of providing the correct value to the appropriate helper function!

See the `ZipPackages` folder for examples.

### Working with meta (virtual) packages

These packages are pretty easy to create in that you don't need a tools folder. Simply define the dependencies that
align with the packages and versions you wish for the package to install, and you are done! See the metapackage folder for examples.

See the `MetaPackage` folder for examples.

### Working with script/configuration packages

Some packages just handle modifying the system. You can include any addiitonal PowerShell scripts you wish to execute as part of the package in the tools folder, and execute them in your install/upgrade/uninstall scripts as appropriate. The key thing here to remember is that a Chocolatey package is _built_ on PowerShell, and can do _anything_ that PowerShell can do!

See the `ScriptBased` folder for examples.

### Working with Portable packages

Portable packages contain one or more executables that don't need to be installed to function.
These tools when used in a Chocolatey package will be shimmed onto your PATH, making them accessible
via your terminal of choice when you need them.

See the `PortablePackage` folder for examples.
