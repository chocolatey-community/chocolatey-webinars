# Portable Package

We’d class just about any executable (or EXE file) that can be run without installation as a CLI executable, and developers of software projects will sometimes publish a separate version of software available to just download and run rather than install. As Chocolatey we will often refer to these types of packages as portable packages.

Use cases: These packages can be very helpful for users who want to have tools quickly available without installation.

They’re generally extremely quick to install, as there’s no additional logic being run, and leave little to no footprint on the computer after removal.

This can be very helpful on a build container, or for tools that just don’t need to be installed.

This package example can also be found on our [How To Create a CLI Executbale Package Guide](https://docs.chocolatey.org/en-us/guides/create/create-cli-package/).