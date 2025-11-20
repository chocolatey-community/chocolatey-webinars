# Requirements

You'll need the `Lenovo.Client.Scripting` module installed in order to create driver packages. This PowerShell module makes it easy to search for, and download driver updates for all supported Lenovo models. To install:

## Installation of Lenovo.Client.Scripting

### Windows PowerShell

```powershell
Install-Module Lenovo.Client.Scripting
```

### PowerShell 7+

```powershell
Install-PSResource Lenovo.Client.Scripting
```

## Finding your machine code

You can find the machine code for a particular model by running the `Get-LenovoMachineCode.ps1` script on the target endpoint.

## Searching for updates

You can use `Get-AvailableLenovoDriver.ps1` to retrieve driver update metadata.

Run `Get-Help .\Get-AvailableLenovoDriver.ps1 -Examples` for usage examples.

## Generate a driver update package

⚠️ Chocolatey packages become unstable once they reach sizes greater than 2GB in size

Here's an example for packaging audio drivers:

1. Find your drivers: `$updates = .\Get-AvailableLenovoDriver.ps1 -MachineType 21NY -UpdateType Driver -OperatingSystem Win11`
2. Filter for only audio drivers: `$audiodrivers = $Uupdates | Where-Object Category -eq 'Audio'`
3. Generate the driver package: `.\New-LenovoDriverPackage.ps1 -PackageId lenovo-audio.driver -UpdateData $audiodrivers -Compile`

This example will find the available drivers for your system (a Thinkpad P16 Gen in the above example), and then create the
`lenovo-audio.driver` package based on our filtered driver data, and store the finished packageg in the current working directory.

## Driver Packs

Leveraging Chocolatey is a powerful way to deploy driver packs, or collections of driver updates, as Chocolatey packages.
Deploying driver packs as packages can be done in two different ways, providing you with a great deal of flexibility: as
a [metapackage](https://docs.chocolatey.org/en-us/guides/create/create-meta-package/), or as a [.config](https://docs.chocolatey.org/en-us/choco/commands/install/#packagesconfig) file.

### As a Metapackage

A metapackage is a Chocolatey package that contains no actual software or files—only dependencies on other packages. Think of it as a "bundle" or "collection" that installs multiple packages with a single command. This is ideal for standardized driver deployments across multiple systems.

**How Metapackages Work:**

- The metapackage's `.nuspec` file defines dependencies on individual driver packages
- When you install the metapackage, Chocolatey's dependency resolver automatically installs all dependent packages
- No `tools` directory or installation scripts are required
- All the heavy lifting is done through dependency management

**Benefits:**

- **Simplified Deployment**: Install an entire driver set with one command (e.g., `choco install lenovo-t14-driverpack -y`)
- **Version Management**: Update the metapackage version to reference newer driver packages
- **Dependency Resolution**: Chocolatey handles the installation order and dependencies automatically
- **Modular Updates**: Update individual driver packages independently, then update the metapackage to reference new versions

**Example Metapackage Structure:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>lenovo-t14-gen3-driverpack</id>
    <version>2025.11.10</version>
    <title>Lenovo ThinkPad T14 Gen 3 Driver Pack</title>
    <authors>Your Organization</authors>
    <description>Complete driver pack for Lenovo ThinkPad T14 Gen 3 (Machine Type 21AH)</description>
    <dependencies>
      <dependency id="lenovo-audio.driver" version="[10.1.1.12]" />
      <dependency id="lenovo-graphics.driver" version="[31.0.15.4601]" />
      <dependency id="lenovo-network.driver" version="[22.120.5.0]" />
      <dependency id="lenovo-chipset.driver" version="[10.1.19013.8254]" />
      <dependency id="lenovo-bluetooth.driver" version="[22.230.0.4]" />
    </dependencies>
  </metadata>
</package>
```

**Creating a Metapackage:**

1. Create the package structure:

   ```powershell
   choco new lenovo-t14-gen3-driverpack --template=default
   ```

2. Edit the `.nuspec` file to add your driver package dependencies

3. Remove the `tools` directory (not needed for metapackages)

4. Pack the metapackage:

   ```powershell
   choco pack lenovo-t14-gen3-driverpack.nuspec
   ```

5. Push to your repository:

   ```powershell
   choco push lenovo-t14-gen3-driverpack.2025.11.10.nupkg --source https://your-repo/
   ```

**Installation:**

```powershell
choco install lenovo-t14-gen3-driverpack -y
```

**Uninstallation Consideration:**  
When uninstalling a metapackage, by default only the metapackage itself is removed—the dependent driver packages remain installed. To remove all dependencies as well, use:

```powershell
choco uninstall lenovo-t14-gen3-driverpack -y --remove-dependencies
```
⚠️ **Warning:** Use `--remove-dependencies` carefully, as it will remove all dependencies which may break other packages that depend on them.

### As a Config File

Chocolatey supports the installation of multiple packages at once using a `packages.config` file (similar to NuGet's packages.config). This is an XML document that lists all packages to install along with optional parameters like version, source, installation arguments, and more. This approach provides maximum flexibility for one-time or ad-hoc driver deployments.

**How Config Files Work:**
- The file is a simple XML document listing package IDs and optional attributes
- Any file ending in `.config` is recognized by Chocolatey (the name doesn't have to be `packages.config`)
- When you run `choco install <filename>.config`, Chocolatey reads the file and installs all listed packages
- Each package can have its own configuration (version, source, parameters, etc.)

**Benefits:**

- **Flexible Deployment**: Easily customize which drivers to install for different scenarios
- **No Package Creation Required**: Skip creating a metapackage—just list the packages you want
- **Quick Testing**: Rapidly test different driver combinations without rebuilding packages
- **Portable Configuration**: Share config files across teams or systems
- **Per-Package Control**: Specify different sources, versions, or parameters for each driver

**Example Config File Structure:**

```xml
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <!-- Basic package with just an ID -->
  <package id="lenovo-audio.driver" />
  
  <!-- Package with specific version -->
  <package id="lenovo-graphics.driver" version="31.0.15.4601" />
  
  <!-- Package from a custom source -->
  <package id="lenovo-network.driver" version="22.120.5.0" source="https://your-repo/chocolatey" />
  
  <!-- Package with all options -->
  <package id="lenovo-chipset.driver" 
           version="10.1.19013.8254"
           source="https://your-repo/chocolatey"
           installArguments="/quiet"
           packageParameters="'/SkipReboot'"
           forceX86="false"
           ignoreDependencies="false"
           />
</packages>
```

**Available Package Attributes:**

- `id` (required): The package identifier
- `version`: Specific version to install (omit for latest)
- `source`: Custom package source/repository
- `installArguments`: Arguments passed to the installer
- `packageParameters`: Parameters passed to the package
- `forceX86`: Force 32-bit installation on 64-bit systems
- `ignoreDependencies`: Skip installing package dependencies
- `executionTimeout`: Timeout in seconds for installation
- `force`: Force reinstallation even if already installed

#### Creating a Config File

You can use the `New-DriverPack.ps1` script to automatically generate a config file based on driver metadata from `Get-AvailableLenovoDriver.ps1`.

**Basic Usage:**

```powershell
# Get driver data
$drivers = .\Get-AvailableLenovoDriver.ps1 -MachineType 21NY -UpdateType Driver -OperatingSystem Win11

# Convert to hashtable format for config generation
$driverPackages = $drivers | ForEach-Object {
    @{
        id = "lenovo-$($_.Category.ToLower() -replace ' ','-').driver"
        version = $_.Version
    }
}

# Generate the config file
.\New-DriverPack.ps1 -Path .\lenovo-t14-drivers.config -DriverPackage $driverPackages
```

**For detailed examples**, run:

```powershell
Get-Help .\New-DriverPack.ps1 -Full
```

#### Installing from a Config File

To install all packages defined in a config file, use the `choco install` command with the path to your config file:

```powershell
# Install from config file in current directory
choco install .\driverpack.config -y

# Install from config file with absolute path
choco install C:\DriverConfigs\lenovo-t14-drivers.config -y

# Install with additional options
choco install .\driverpack.config -y --force --ignore-dependencies
```

**What Happens During Installation:**

1. Chocolatey reads the config file
2. Each package is processed in the order listed
3. Package-specific options (version, source, parameters) are applied
4. Dependencies are resolved (unless `ignoreDependencies="true"`)
5. Installation proceeds for each package sequentially

**Use Cases:**

- **Machine-Specific Deployments**: Create different config files for different machine types or configurations
- **Testing**: Quickly test driver combinations before creating permanent metapackages
- **One-Off Installations**: Deploy drivers to a specific machine without creating a formal package
- **Rapid Updates**: Update the config file and re-run to install newer driver versions

**Config vs. Metapackage Decision Matrix:**

| **Use Case** | **Config File** | **Metapackage** |
|-------------|----------------|----------------|
| Quick testing | ✅ Better | ❌ Slower |
| Formal deployments | ❌ Less ideal | ✅ Better |
| Version control | ✅ Easy to track | ✅ Package versioned |
| Reusability | ⚠️ Manual distribution | ✅ Repository distribution |
| Dependency management | ⚠️ Manual listing | ✅ Automatic |
| Standardization | ❌ Less consistent | ✅ Highly consistent |

## Jenkins Integration

This repository includes Jenkins integration to automate the creation of Lenovo driver packages through a CI/CD pipeline. The Jenkins job provides a parameterized interface for building driver packages on-demand or on a schedule.

### Prerequisites

- Jenkins server with PowerShell plugin installed
- `Chocolatey.Lenovo.DriverMgmt` module installed on the Jenkins agent
- `Lenovo.Client.Scripting` module installed on the Jenkins agent
- Appropriate permissions for the Jenkins service account to create packages

### Installing the Jenkins Job

The repository includes two files in the `jenkins` folder:

1. **`config.xml`** - The Jenkins job configuration that defines the pipeline and parameters
2. **`Install-Job.ps1`** - A PowerShell script to deploy the job to your Jenkins instance

#### Using Install-Job.ps1

The `Install-Job.ps1` script automates the installation of the Jenkins job by copying the configuration file to the appropriate Jenkins directory and restarting the service.

**Basic Usage:**

```powershell
# Install with default settings (job name: "Build Driver Package")
.\Install-Job.ps1 -JobFile .\config.xml

# Install with a custom job name
.\Install-Job.ps1 -Name "Lenovo Driver Builder" -JobFile .\config.xml

# Install to a custom Jenkins home directory
.\Install-Job.ps1 -JenkinsHome "D:\Jenkins" -Name "Build Drivers" -JobFile .\config.xml
```

**For detailed help:**

```powershell
Get-Help .\Install-Job.ps1 -Full
```

**What the script does:**

1. Validates that the Jenkins service is present
2. Creates the job folder structure in Jenkins home directory
3. Copies the XML configuration file
4. Restarts Jenkins to register the new job

⚠️ **Note:** You need administrative privileges to restart the Jenkins service.

### Jenkins Job Parameters

Once installed, the Jenkins job exposes the following parameters for building driver packages:

| Parameter | Description | Valid Values | Example |
|-----------|-------------|--------------|---------|
| `MODEL_LIST` | Comma-separated list of Lenovo model names | Any valid Lenovo model name | `ThinkPad X1 Carbon, ThinkPad P16 Gen 2` |
| `MACHINE_TYPE` | Comma-separated list of machine type codes | 4-character Lenovo machine codes | `21FA, 20QN, 21NY` |
| `UPDATE_TYPE` | Type of update to package | `Application`, `Driver`, `Bios`, `Firmware` | `Driver` |
| `REBOOT_TYPE` | Filter by reboot requirement | `Forced reboot`, `Requires reboot`, `Forces shutdown`, `Delayed forced reboot` | `Requires reboot` |
| `SEVERITY` | Filter by update severity | `Critical`, `Recommended`, `Other` | `Critical` |
| `OPERATING_SYSTEM` | Target Windows version | `Win10`, `Win11` | `Win11` |
| `OUTPUT_DIRECTORY` | Where to save packages | Any valid Windows path | `C:\drivers` |
| `CATEGORY` | Driver category filter (Driver type only) | See category list below | `Audio, Networking Wireless LAN` |

**Valid Category Values:**

- `Audio`
- `Bluetooth and Modem`
- `Camera and Card Reader`
- `Display and Video Graphics`
- `Docking Station and Port Replicator`
- `Fingerprint reader`
- `Motherboard Devices Backplanes core chipset onboard video PCIe switches`
- `Mouse Pen and Keyboard`
- `Networking Wireless LAN`
- `Networking Wireless WAN`
- `Power Management`
- `Software and Utilities`
- `Storage`
- `USB Device FireWire IEEE 1394 Thunderbolt`

### How the Jenkins Job Works

The Jenkins pipeline job uses a PowerShell script block that:

1. **Collects Parameters**: Reads all job parameters from environment variables
2. **Converts to PowerShell**: Transforms environment variable names (e.g., `MODEL_LIST`) to PascalCase parameter names (e.g., `ModelList`)
3. **Filters Empty Values**: Only includes parameters that have values
4. **Invokes Get-LenovoDriver**: Calls the `Get-LenovoDriver` function with all provided parameters using splatting

**Pipeline Script Overview:**

```powershell
node {
  powershell '''
    $commandArgs = @{}

    @(
      'MODEL_LIST'
      'MACHINE_TYPE'
      'UPDATE_TYPE'
      'CATEGORY'
      'REBOOT_TYPE'
      'SEVERITY'
      'OPERATING_SYSTEM'
      'OUTPUT_DIRECTORY'
    ) | ForEach-Object {
      $value = [System.Environment]::GetEnvironmentVariable($_)
      
      if (-not [String]::IsNullOrEmpty($value)) {
        # Convert to PascalCase
        $pascalCaseName = (Get-Culture).TextInfo.ToTitleCase($_.ToLower()).Replace('_', '')
        $commandArgs[$pascalCaseName] = $value
      }
    }
    
    Get-LenovoDriver @commandArgs
  '''
}
```

### Usage Examples

#### Example 1: Build Audio Drivers for Multiple Machine Types

```yaml
MODEL_LIST: (leave empty)
MACHINE_TYPE: 21FA, 20QN
UPDATE_TYPE: Driver
CATEGORY: Audio
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

#### Example 2: Build All Critical Updates for a Model

```yaml
MODEL_LIST: ThinkPad X1 Carbon
MACHINE_TYPE: (leave empty)
UPDATE_TYPE: Driver
SEVERITY: Critical
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

#### Example 3: Build Specific Driver Categories

```yaml
MODEL_LIST: (leave empty)
MACHINE_TYPE: 21NY
UPDATE_TYPE: Driver
CATEGORY: Audio, Networking Wireless LAN, Display and Video Graphics
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

### Scheduling Builds

You can configure the Jenkins job to run on a schedule using standard Jenkins cron syntax:

1. Open the Jenkins job configuration
2. Under "Build Triggers", enable "Build periodically"
3. Enter a cron expression, for example:
   - `H 2 * * *` - Run daily at 2 AM
   - `H H * * 0` - Run weekly on Sunday
   - `H H 1 * *` - Run monthly on the 1st

### Troubleshooting

**Job fails with "Module not found":**
- Ensure `Chocolatey.Lenovo.DriverMgmt` and `Lenovo.Client.Scripting` modules are installed in a location accessible to the Jenkins service account
- Try installing modules system-wide: `Install-Module -Name Lenovo.Client.Scripting -Scope AllUsers`

**Permission denied when creating packages:**
- Verify the Jenkins service account has write permissions to the `OUTPUT_DIRECTORY`
- Check that the Jenkins service account can execute Chocolatey commands

**Jenkins doesn't show the new job after installation:**
- Ensure the Jenkins service restarted successfully
- Check Jenkins logs for errors: `C:\ProgramData\Jenkins\.jenkins\logs`
- Verify the job folder was created: `C:\ProgramData\Jenkins\.jenkins\jobs\[JobName]`

**Parameters not being passed correctly:**
- Ensure parameter values don't contain quotes unless needed
- For comma-separated values, use commas without spaces: `21FA,20QN,21NY`
- Empty parameters are ignored by the script—this is expected behavior
