# Dell Driver Management for Chocolatey

PowerShell module for automating the creation of Chocolatey packages for Dell hardware drivers. This module provides comprehensive tools for downloading, extracting, and packaging Dell drivers for enterprise deployment.

## 📦 Module: Chocolatey.Dell.DriverMgmt

This module streamlines Dell driver management by providing functions to:

- Download and parse Dell driver catalogs
- Download complete driver packs by model and OS
- Extract and organize CAB files
- Parse driver manifests for metadata
- Create Chocolatey packages from various sources

## 🚀 Getting Started

### Installation

```powershell
# Import the module
Import-Module .\Dell\Chocolatey.Dell.Drivermgmt\Chocolatey.Dell.DriverMgmt.psd1 -Force
```

### Prerequisites

- PowerShell 5.1 or later
- Chocolatey installed and configured
- Internet connection for downloading drivers

## 📚 Functions

### Get-DellCatalog

Downloads the latest Dell driver catalog from Dell's servers.

**Usage:**

```powershell
Get-DellCatalog -DestinationFolder .\catalog
```

**Parameters:**

- `DestinationFolder` - Where to save the downloaded catalog file

### Get-DellDriverPack

Downloads complete driver packs for specific Dell models and operating systems.

**Usage:**

```powershell
$packArgs = @{
    DriverCatalog  = '.\catalog\DriverPackCatalog.xml'
    DownloadFolder = '.\driverpack'
    TargetModel    = 'Latitude 5550'
    TargetOS       = 'Windows11'
}
Get-DellDriverPack @packArgs
```

**Parameters:**

- `DriverCatalog` - Path to the DriverPackCatalog.xml file
- `DownloadFolder` - Where to download driver packs
- `TargetModel` - Dell model name (e.g., 'Latitude 5550', 'OptiPlex 7090')
- `TargetOS` - Operating system version

**Supported OS Values:**

- Windows7, Windows8, Windows81, Windows10, Windows11
- WinPE3, WinPE4, WinPE5, WinPE10

**Folder Structure:**

Driver packs are organized as: `DownloadFolder\ModelName\OS\files`

### Get-DellDriverFromCAB

Downloads and extracts individual drivers from CAB files based on the Dell catalog.

**Usage:**

```powershell
$cabArgs = @{
    DriverCatalog  = '.\catalog\DriverPackCatalog.xml'
    DownloadFolder = '.\cab'
    TargetModel    = 'Latitude 5420'
    TargetOS       = 'Windows10'
}
Get-DellDriverFromCAB @cabArgs
```

**Parameters:**

- `DriverCatalog` - Path to the catalog XML file
- `DownloadFolder` - Where to extract CAB contents
- `TargetModel` - Dell model name
- `TargetOS` - Operating system version

### Get-DellDriverManifestInfo

Parses Dell Manifest.xml files to extract driver metadata including categories, versions, and paths.

**Usage:**

```powershell
# Get all drivers from manifest
$manifest = Get-DellDriverManifestInfo -Path '.\cab\Latitude 5420\Manifest.xml'

# Filter by category
$audioDrivers = Get-DellDriverManifestInfo -Path '.\manifest.xml' -Category 'audio'
$chipsetDrivers = Get-DellDriverManifestInfo -Path '.\manifest.xml' -Category 'audio', 'chipset'
```

**Parameters:**

- `Path` - Path to the Manifest.xml file
- `Category` - Optional filter for driver categories (supports arrays)

**Common Categories:**

- audio
- video
- network
- chipset
- storage
- input

### New-DellDriverPackage

Creates Chocolatey packages from Dell drivers using three different templates.

**Templates:**

1. **delldriverpack** - For complete driver pack executables
2. **delldriver** - For individual drivers from extracted CAB/manifest
3. **delldcu** - For Dell Command Update utility

**Usage Examples:**

#### Create Package from URL (Driver Pack)

```powershell
$packageArgs = @{
    PackageId       = 'dell-latitude7450win11.driver'
    DriverPack      = 'https://example.com/drivers/Latitude-7450_Win11_A07.exe'
    Template        = 'delldriverpack'
    OutputDirectory = 'C:\repository\dell'
    Compile         = $true
}
New-DellDriverPackage @packageArgs
```

#### Create Package from Local File

```powershell
$packageArgs = @{
    PackageId       = 'dell-optiplex7090.driver'
    DriverPack      = 'C:\downloads\OptiPlex-7090_Win10_A12.exe'
    Template        = 'delldriverpack'
    OutputDirectory = 'C:\repository\dell'
    Compile         = $true
}
New-DellDriverPackage @packageArgs
```

#### Create Package from Manifest (Filtered by Category)

```powershell
$packageArgs = @{
    PackageId       = 'dell-latitude5420audio.driver'
    Template        = 'delldriver'
    Category        = 'audio', 'chipset'
    Metadata        = '.\cab\Latitude 5420\5420-win10-A10-7PYRM\5420\Manifest.xml'
    OutputDirectory = 'C:\repository\dell'
    Compile         = $true
}
New-DellDriverPackage @packageArgs
```

**Parameters:**

- `PackageId` - Unique identifier for the Chocolatey package
- `DriverPack` - URL or local path to driver pack (for delldriverpack/delldcu templates)
- `Metadata` - Path to Manifest.xml file (for delldriver template)
- `Category` - Optional array of categories to filter drivers (for delldriver template)
- `Template` - Which Chocolatey template to use
- `OutputDirectory` - Where to create the package
- `Compile` - If $true, automatically runs `choco pack` to create .nupkg file

### Expand-DellDriverFile

Low-level function to extract CAB files containing Dell driver catalogs.

**Usage:**

```powershell
Expand-DellDriverFile -Path .\driverpackcatalog.cab -DestinationFolder .\catalog
```

## 🔄 Common Workflows

### Workflow 1: Download and Package a Driver Pack

```powershell
# 1. Download the catalog
Get-DellCatalog -DestinationFolder .\catalog

# 2. Download driver pack for specific model
Get-DellDriverPack -DriverCatalog '.\catalog\DriverPackCatalog.xml' `
    -DownloadFolder '.\driverpack' `
    -TargetModel 'Latitude 5550' `
    -TargetOS 'Windows11'

# 3. Create Chocolatey package from downloaded pack
$driverFile = Get-ChildItem '.\driverpack\Latitude 5550\Windows11\*.exe' | Select-Object -First 1
New-DellDriverPackage -PackageId 'dell-latitude5550win11.driver' `
    -DriverPack $driverFile.FullName `
    -Template 'delldriverpack' `
    -OutputDirectory 'C:\repository' `
    -Compile
```

### Workflow 2: Extract CAB and Create Filtered Driver Packages

```powershell
# 1. Download catalog
Get-DellCatalog -DestinationFolder .\catalog

# 2. Download and extract CAB for model
Get-DellDriverFromCAB -DriverCatalog '.\catalog\DriverPackCatalog.xml' `
    -DownloadFolder '.\cab' `
    -TargetModel 'Latitude 5420' `
    -TargetOS 'Windows10'

# 3. Find the manifest
$manifest = Get-ChildItem '.\cab\Latitude 5420' -Recurse -Filter 'Manifest.xml' | Select-Object -First 1

# 4. Create audio driver package only
New-DellDriverPackage -PackageId 'dell-latitude5420audio.driver' `
    -Template 'delldriver' `
    -Category 'audio' `
    -Metadata $manifest.FullName `
    -OutputDirectory 'C:\repository' `
    -Compile

# 5. Create network driver package only
New-DellDriverPackage -PackageId 'dell-latitude5420network.driver' `
    -Template 'delldriver' `
    -Category 'network' `
    -Metadata $manifest.FullName `
    -OutputDirectory 'C:\repository' `
    -Compile
```

### Workflow 3: Package from ProGet/Nexus URL

If you've already uploaded driver packs to an internal repository:

```powershell
New-DellDriverPackage -PackageId 'dell-precision5570.driver' `
    -DriverPack 'https://proget.company.com/drivers/Precision-5570_Win11_A09.exe' `
    -Template 'delldriverpack' `
    -OutputDirectory 'C:\choco-packages' `
    -Compile
```

## 📝 Tips and Best Practices

### Model Matching

The module uses exact model name matching. Dell's catalog may have multiple entries for similar models:

- "Latitude 5550" is different from "Latitude 5550 (Legacy)"
- Use the exact model name as it appears in Dell's catalog

### Folder Organization

Driver packs are automatically organized as:

```
DownloadFolder/
└── ModelName/
    └── OS/
        └── DriverPackFile.exe
```

CAB extractions are organized as:

```
DownloadFolder/
└── ModelName/
    └── [CAB Contents]/
        └── Manifest.xml
```

### Category Filtering

Category filtering is only available when using the `delldriver` template with a Manifest.xml file:

- Reduces package size by including only needed drivers
- Common categories: audio, video, network, chipset, storage
- Supports multiple categories in a single package

### Package Compilation

When `Compile` is set to `$true`:

- The module automatically runs `choco pack`
- Creates a `.nupkg` file ready for deployment
- Package is placed in the `OutputDirectory`

## 🔍 Troubleshooting

**"Model not found in catalog"**

- Ensure you're using the exact model name from Dell's catalog
- Download a fresh catalog: `Get-DellCatalog -DestinationFolder .\catalog`
- Check for typos in the model name

**"CAB extraction failed"**

- Ensure you have permissions to write to the destination folder
- Check available disk space
- Try running PowerShell as administrator

**"Manifest.xml not found"**

- Ensure you've extracted the CAB first with `Get-DellDriverFromCAB`
- Verify the path to the manifest file
- The manifest is typically located several folders deep in the extracted structure

**"Package creation failed"**

- Verify Chocolatey is installed: `choco --version`
- Check that the template exists in the Chocolatey templates folder
- Ensure you have write permissions to `OutputDirectory`

## 📖 Getting Help

All functions include comprehensive help documentation:

```powershell
# View help for any function
Get-Help Get-DellDriverPack -Full
Get-Help New-DellDriverPackage -Examples
Get-Help Get-DellDriverManifestInfo -Detailed
```

## 🔗 Additional Resources

- [Dell Driver Pack Catalog](https://www.dell.com/support/kbdoc/000122176/driver-pack-catalog)
- [Chocolatey Documentation](https://docs.chocolatey.org/)
- [Main Repository README](../README.md)
