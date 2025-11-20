# Driver Package Management for Chocolatey

This repository contains PowerShell modules and automation tools for creating Chocolatey packages for Dell and Lenovo hardware drivers. These tools streamline the process of downloading, organizing, and packaging drivers for enterprise deployment via Chocolatey package management.

## 🎯 Overview

Managing hardware drivers across an enterprise can be challenging. This project provides comprehensive PowerShell modules and Jenkins integration that automate:

- **Download** driver catalogs and packages from Dell and Lenovo
- **Extract and organize** driver files with intelligent folder structures
- **Create Chocolatey packages** with proper metadata and dependencies
- **Support bulk operations** for creating multiple driver packages
- **Generate metapackages** for deploying driver collections
- **Automate with Jenkins** for CI/CD driver package creation

## 📦 Components

### [Dell Driver Management](./Dell/README.md)

PowerShell module (`Chocolatey.Dell.DriverMgmt`) for managing Dell driver packages with support for:

- Driver catalog downloads and parsing
- Multiple OS support (Windows 7-11, WinPE variants)
- Model-specific driver pack downloads
- CAB file extraction and organization
- Manifest-based driver packaging with category filtering

[View Dell Documentation →](./Dell/README.md)

### [Lenovo Driver Management](./Lenovo/README.md)

PowerShell module (`Chocolatey.Lenovo.DriverMgmt`) for managing Lenovo driver packages with:

- Machine type and model lookup
- Update type filtering (Drivers, BIOS, Firmware, Applications)
- Category-based driver filtering
- Version transformation for complex version strings
- Metapackage creation with dependency management
- Bulk package creation scripts

[View Lenovo Documentation →](./Lenovo/README.md)

### [Jenkins Integration](./jenkins/README.md)

Automated Jenkins pipeline for building driver packages with:

- Parameterized job configuration
- Support for both Dell and Lenovo drivers
- Scheduled or on-demand builds
- Easy installation script

[View Jenkins Documentation →](./jenkins/README.md)

## 🚀 Quick Start

### Setup

```powershell
# Set execution policy for the session
Set-ExecutionPolicy Bypass -Scope Process -Force

# Import both modules
Import-Module .\Dell\Chocolatey.Dell.Drivermgmt\Chocolatey.Dell.DriverMgmt.psd1 -Force
Import-Module .\Lenovo\Chocolatey.Lenovo.DriverMgmt\Chocolatey.Lenovo.DriverMgmt.psd1 -Force
```

### Quick Examples

#### Dell: Download and Package a Driver Pack

```powershell
# Download catalog
Get-DellCatalog -DestinationFolder .\catalog

# Download driver pack
Get-DellDriverPack -DriverCatalog '.\catalog\DriverPackCatalog.xml' `
    -DownloadFolder '.\driverpack' `
    -TargetModel 'Latitude 5550' `
    -TargetOS 'Windows11'

# Create package
New-DellDriverPackage -PackageId 'dell-latitude5550.driver' `
    -DriverPack 'https://example.com/Latitude-5550_Win11.exe' `
    -Template 'delldriverpack' `
    -Compile
```

#### Lenovo: Find and Package Drivers

```powershell
# Find available drivers
$drivers = Get-AvailableLenovoDriver -MachineType 21FA `
    -UpdateType Driver `
    -Category 'Audio' `
    -OperatingSystem Win11

# Create package
New-LenovoDriverPackage -PackageId 'lenovo-thinkpad-audio.driver' `
    -UpdateData $drivers `
    -Compile
```

## 🗂️ Repository Structure

```yaml
webinar/
├── README.md                            # This file - overview and links
├── Dell/
│   ├── README.md                        # Dell-specific documentation
│   └── Chocolatey.Dell.Drivermgmt/
│       ├── public/                      # Public functions
│       ├── Chocolatey.Dell.DriverMgmt.psd1
│       └── Chocolatey.Dell.DriverMgmt.psm1
├── Lenovo/
│   ├── README.md                        # Lenovo-specific documentation
│   ├── Chocolatey.Lenovo.DriverMgmt/
│   │   ├── public/                      # Public functions
│   │   ├── private/                     # Helper functions
│   │   ├── Chocolatey.Lenovo.DriverMgmt.psd1
│   │   └── Chocolatey.Lenovo.DriverMgmt.psm1
│   └── BulkCreate.ps1                   # Bulk package creation
├── jenkins/
│   ├── README.md                        # Jenkins integration docs
│   ├── config.xml                       # Jenkins job configuration
│   └── Install-Job.ps1                  # Job installation script
├── Chocolatey/                          # Chocolatey package templates
└── Demo.ps1                             # Comprehensive demo script
```

## 🛠️ Requirements

- **PowerShell 5.1** or later
- **Chocolatey** installed and configured
- **Internet connection** for downloading drivers and catalogs

**For Lenovo:**

- `Lenovo.Client.Scripting` PowerShell module

**For Jenkins:**

- Jenkins server with PowerShell plugin
- Both driver management modules installed on Jenkins agent

## 📖 Documentation

Each component has detailed documentation in its respective folder:

- **[Dell Documentation](./Dell/README.md)** - Functions, examples, and workflows for Dell driver management
- **[Lenovo Documentation](./Lenovo/README.md)** - Functions, examples, driver packs, and metapackages
- **[Jenkins Documentation](./jenkins/README.md)** - Automated build configuration and usage

## � Demo Script

A comprehensive `Demo.ps1` script is included that demonstrates:

- Module import and setup
- Catalog downloads and extraction
- Driver pack downloads for specific models
- Package creation from URLs, local files, and manifests
- Bulk package creation
- Metapackage generation

Run sections interactively to see each feature in action.

## 🤝 Contributing

This is a webinar demonstration project showcasing enterprise driver management with Chocolatey. Feel free to adapt and extend for your organization's needs.

## 🔗 Additional Resources

- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [Dell Driver Catalog](https://www.dell.com/support/kbdoc/000122176/driver-pack-catalog)
- [Lenovo System Update Catalog](https://support.lenovo.com/)
