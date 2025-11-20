# Chocolatey Driver Package Templates

This folder contains Chocolatey package templates and scripts to help you automate the deployment of hardware drivers in your organization using Chocolatey package management.

## Overview

Driver deployment can be challenging in enterprise environments. These templates simplify the process by:
- Packaging drivers in a standardized Chocolatey format
- Managing driver dependencies automatically
- Enabling centralized driver distribution through your Chocolatey repository
- Providing consistent installation and update mechanisms

## Available Templates

Two vendor-specific templates are provided to package drivers for deployment:

### 1. Dell Driver Template
**Location:** [delldriver](/Chocolatey/template/delldriver/)  
**Purpose:** Package Dell-specific drivers using standard Chocolatey packaging conventions.

**Use Case:** Deploy drivers for Dell hardware (Latitude, Precision, OptiPlex, etc.) through your Chocolatey infrastructure.

### 2. Lenovo Driver Template
**Location:** [lenovo](/Chocolatey/template/lenovo/)  
**Purpose:** Package Lenovo-specific drivers with automatic Thin Installer integration.

**Key Features:**
- Automatically declares a dependency on the `lenovo-thininstaller` package
- Uses Thin Installer's silent installation capabilities
- Supports repository-based driver installation with logging
- Compatible with Lenovo commercial systems (ThinkPad, ThinkCentre, ThinkStation)

**How it Works:**
The Lenovo template creates packages that store driver files in a local repository folder. During installation, the package invokes Thin Installer with the following parameters:
```powershell
/CM -search A -action INSTALL -noicon -repository '<path>' -noreboot -log '<logfile>'
```
This ensures drivers are installed silently without user interaction and without forcing an immediate reboot.

## Installing the Templates

Before creating driver packages, you must install the templates into your Chocolatey templates directory. This makes them available to the `choco new` command.

### Prerequisites
- Chocolatey must be installed
- Elevated PowerShell session (Run as Administrator)
- Write permissions to `C:\ProgramData\chocolatey\templates`

### Installation Steps

1. Navigate to the Chocolatey folder in this repository
2. Run the template installation script:

```powershell
.\Install-Template.ps1
```

**What This Does:**
- Checks if `C:\ProgramData\chocolatey\templates` exists
- Creates the directory if needed
- Copies both `delldriver` and `lenovo` templates to the Chocolatey templates directory

**Verification:**
After installation, verify the templates are available:
```powershell
choco template list
```

You should see `delldriver` and `lenovo` in the output.

## Lenovo Thin Installer Package

### What is Lenovo Thin Installer?

Lenovo Thin Installer is a lightweight, portable utility that identifies and deploys system updates, drivers, BIOS updates, and applications for Lenovo commercial systems. Unlike Lenovo System Update (which requires installation), Thin Installer:
- Does not require installation itself
- Can run from any location
- Supports command-line operation for automation
- Enables silent, unattended driver deployments
- Works with local or network-based driver repositories

**Official Documentation:** [Lenovo Tools for Administrators](https://support.lenovo.com/solutions/ht037099)

### Why Package Thin Installer?

The Lenovo driver template packages created in this repository depend on Thin Installer being present on target systems. By packaging Thin Installer as a Chocolatey package:
1. **Dependency Management:** The `lenovo` template automatically declares it as a dependency
2. **Consistent Deployment:** Ensures all systems have the same version of Thin Installer
3. **Simplified Distribution:** Deploy once through Chocolatey, use for all Lenovo driver packages
4. **Centralized Updates:** Update Thin Installer across your organization by updating the package

### Creating the Thin Installer Package

**Prerequisites:**
- Chocolatey CLI installed
- **Chocolatey for Business (C4B) license required** - The script uses the `--build-package` flag which is only available in C4B
- Internet access to download Thin Installer from Lenovo
- Elevated PowerShell session

**Command:**
```powershell
.\New-ThinInstallerPackage.ps1
```

**What This Script Does:**
1. Validates Chocolatey CLI is installed
2. Checks for a valid C4B license at `C:\ProgramData\chocolatey\license\chocolatey.license.xml`
3. Creates a new Chocolatey package for Thin Installer
4. Downloads the Thin Installer executable from Lenovo (default: version 1.04.02.00024)
5. Automatically compiles the package into a `.nupkg` file using Package Builder
6. Outputs the package to the current directory (or specified `OutputDirectory`)

**Customization Options:**
```powershell
# Create package in a specific directory
.\New-ThinInstallerPackage.ps1 -OutputDirectory 'C:\ChocolateyPackages'

# Use a different version of Thin Installer
.\New-ThinInstallerPackage.ps1 -DownloadLocation 'https://download.lenovo.com/path/to/version.exe'

# Specify a custom package ID
.\New-ThinInstallerPackage.ps1 -PackageId 'lenovo-thininstaller-v2'
```

### Deploying the Thin Installer Package

After creating the package, deploy it to your Chocolatey repository:

```powershell
# Push to your internal Chocolatey repository
choco push lenovo-thininstaller.1.4.2.24.nupkg --source='https://your-chocolatey-server/'

# Or install directly for testing
choco install lenovo-thininstaller -y --source='path\to\nupkg\folder'
```

## Workflow Summary

### For Lenovo Drivers:
1. **Install Templates:** Run `.\Install-Template.ps1` to make templates available
2. **Create Thin Installer Package:** Run `.\New-ThinInstallerPackage.ps1` and deploy to your repository
3. **Create Driver Packages:** Use `choco new <package-name> --template=lenovo` to generate driver packages
4. **Deploy Drivers:** Install driver packages on target systems - Thin Installer dependency is handled automatically

### For Dell Drivers:
1. **Install Templates:** Run `.\Install-Template.ps1` to make templates available
2. **Create Driver Packages:** Use `choco new <package-name> --template=delldriver` to generate driver packages
3. **Deploy Drivers:** Install driver packages on target systems

## Additional Resources

- [Chocolatey Package Templates Documentation](https://docs.chocolatey.org/en-us/features/package-builder/setup)
- [Chocolatey for Business Features](https://chocolatey.org/compare)
- [Lenovo Support: Tools for Administrators](https://support.lenovo.com/solutions/ht037099)

## Troubleshooting

**Templates not showing in `choco template list`:**
- Ensure you ran `Install-Template.ps1` with administrator privileges
- Check that templates exist in `C:\ProgramData\chocolatey\templates`

**New-ThinInstallerPackage.ps1 fails with "Chocolatey for Business license is required":**
- This script requires a valid C4B license
- Verify license exists at `C:\ProgramData\chocolatey\license\chocolatey.license.xml`
- Contact your Chocolatey account manager if you need a license

**Lenovo driver packages fail to install:**
- Ensure `lenovo-thininstaller` package is installed first or available in your repository
- Check that Thin Installer exists at `C:\Program Files (x86)\Lenovo\ThinInstaller\ThinInstaller.exe`
- Review installation logs in `%TEMP%\<package-name>\`
