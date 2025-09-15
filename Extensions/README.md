# Unwrapping Chocolatey: Extensions

The resources in this folder were used in the September 2025 Unwrapping Chocolatey webinar about Chocolatey Extensions.
Each folder contains a Chocolatey package, and some information about it.

## What Are Chocolatey Extensions?

Chocolatey Extensions are PowerShell Modules that live in a special `extensions` folder within your Chocolatey installation.
Chocolatey treats this folder as part of your module path, ensuring the functions available via any installed extensions are
ready to go in the PowerShell host used by choco during install, upgrade, and uninstall operations.

## Creating a Chocolatey Extension

We have a [guide](https://docs.chocolatey.org/en-us/guides/create/create-extension-package/) available that walks you through creating your first extension.

## Getting help

Licensed customers with an active support agreement can run `choco support` from a licensed Chocolatey node to reach out for help.
Users of Open Source Chocolatey have community assistance available on our [Discord](https://ch0.co/community) server.
