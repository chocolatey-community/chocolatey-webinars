# Jenkins Integration for Driver Package Management

Automated Jenkins pipeline for building Dell and Lenovo driver Chocolatey packages on-demand or on a schedule. This integration provides a parameterized job that leverages the PowerShell driver management modules to create packages in a CI/CD workflow.

## 🎯 Overview

The Jenkins integration provides:

- **Parameterized Build Job** - Easily configure driver package builds through Jenkins UI
- **Automated Package Creation** - Hands-off driver package generation
- **Scheduled Builds** - Create packages on a regular cadence
- **Easy Installation** - Simple PowerShell script to deploy the job

## 📦 Files

- **config.xml** - Jenkins job configuration (Pipeline/Workflow job)
- **Install-Job.ps1** - PowerShell script to install the job on your Jenkins server

## 🚀 Getting Started

### Prerequisites

Before installing the Jenkins job, ensure:

1. **Jenkins Server** with PowerShell plugin installed
2. **PowerShell Modules** installed on Jenkins agent:
   - `Chocolatey.Dell.DriverMgmt`
   - `Chocolatey.Lenovo.DriverMgmt`
   - `Lenovo.Client.Scripting` (for Lenovo functionality)
3. **Chocolatey** installed on Jenkins agent
4. **Permissions** for Jenkins service account to:
   - Create files in output directories
   - Execute Chocolatey commands
   - Run PowerShell scripts

### Installing the Jenkins Job

Use the included `Install-Job.ps1` script to deploy the job to your Jenkins instance.

#### Basic Usage

```powershell
# Install with default settings (job name: "Build Driver Package")
.\Install-Job.ps1 -JobFile .\config.xml
```

#### Custom Job Name

```powershell
# Install with a custom job name
.\Install-Job.ps1 -Name "Lenovo Driver Builder" -JobFile .\config.xml
```

#### Custom Jenkins Home

```powershell
# Install to a custom Jenkins home directory
.\Install-Job.ps1 -JenkinsHome "D:\Jenkins" -Name "Build Drivers" -JobFile .\config.xml
```

#### Parameters

- `JenkinsHome` - Path to Jenkins home directory (default: `C:\ProgramData\Jenkins\.jenkins`)
- `Name` - Job name as it will appear in Jenkins (default: `Build Driver Package`)
- `JobFile` - Path to the config.xml file (required)

#### What the Script Does

1. Validates that the Jenkins service is running
2. Creates the job folder structure in Jenkins home directory
3. Copies the XML configuration file to the job folder
4. Restarts Jenkins service to register the new job

⚠️ **Note:** You need administrative privileges to restart the Jenkins service.

#### View Help

```powershell
Get-Help .\Install-Job.ps1 -Full
```

## 🎛️ Job Parameters

Once installed, the Jenkins job exposes the following parameters for customizing driver package builds:

| Parameter | Description | Valid Values | Example |
|-----------|-------------|--------------|---------|
| `MODEL_LIST` | Comma-separated list of Lenovo model names | Any valid Lenovo model name | `ThinkPad X1 Carbon, ThinkPad P16 Gen 2` |
| `MACHINE_TYPE` | Comma-separated list of Lenovo machine type codes | 4-character machine codes | `21FA, 20QN, 21NY` |
| `UPDATE_TYPE` | Type of update to package | `Application`, `Driver`, `Bios`, `Firmware` | `Driver` |
| `REBOOT_TYPE` | Filter by reboot requirement | `Forced reboot`, `Requires reboot`, `Forces shutdown`, `Delayed forced reboot` | `Requires reboot` |
| `SEVERITY` | Filter by update severity | `Critical`, `Recommended`, `Other` | `Critical` |
| `OPERATING_SYSTEM` | Target Windows version | `Win10`, `Win11` | `Win11` |
| `OUTPUT_DIRECTORY` | Where to save created packages | Any valid Windows path | `C:\drivers` (default) |
| `CATEGORY` | Driver category filter (Driver type only) | See category list below | `Audio, Networking Wireless LAN` |

### Parameter Notes

- **MODEL_LIST vs MACHINE_TYPE**: Use one or the other, not both
  - `MODEL_LIST` is user-friendly (e.g., "ThinkPad X1 Carbon")
  - `MACHINE_TYPE` is more precise (e.g., "21FA")
- **CATEGORY**: Only available when `UPDATE_TYPE` is set to `Driver`
- **Empty Parameters**: Parameters left empty are ignored by the pipeline

### Valid Category Values

When `UPDATE_TYPE` is set to `Driver`, you can filter by these categories:

- Audio
- Bluetooth and Modem
- Camera and Card Reader
- Display and Video Graphics
- Docking Station and Port Replicator
- Fingerprint reader
- Motherboard Devices Backplanes core chipset onboard video PCIe switches
- Mouse Pen and Keyboard
- Networking Wireless LAN
- Networking Wireless WAN
- Power Management
- Software and Utilities
- Storage
- USB Device FireWire IEEE 1394 Thunderbolt

## 🔧 How It Works

The Jenkins job uses a PowerShell script block that:

1. **Collects Parameters** from Jenkins environment variables
2. **Converts Names** from UPPER_SNAKE_CASE to PascalCase for PowerShell
3. **Filters Empty Values** - only includes parameters with values
4. **Invokes Get-LenovoDriver** with all provided parameters using splatting

### Pipeline Script Overview

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
        # Convert UPPER_SNAKE_CASE to PascalCase
        $pascalCaseName = (Get-Culture).TextInfo.ToTitleCase($_.ToLower()).Replace('_', '')
        $commandArgs[$pascalCaseName] = $value
      }
    }
    
    "Using parameters:"
    $commandArgs
    
    # Execute driver package creation
    Get-LenovoDriver @commandArgs
  '''
}
```

### Environment Variable Mapping

Jenkins parameters are converted as follows:

| Jenkins Parameter | PowerShell Parameter |
|-------------------|---------------------|
| `MODEL_LIST` | `ModelList` |
| `MACHINE_TYPE` | `MachineType` |
| `UPDATE_TYPE` | `UpdateType` |
| `CATEGORY` | `Category` |
| `REBOOT_TYPE` | `RebootType` |
| `SEVERITY` | `Severity` |
| `OPERATING_SYSTEM` | `OperatingSystem` |
| `OUTPUT_DIRECTORY` | `OutputDirectory` |

## 📋 Usage Examples

### Example 1: Build Audio Drivers for Multiple Machine Types

```yaml
MODEL_LIST: (leave empty)
MACHINE_TYPE: 21FA, 20QN
UPDATE_TYPE: Driver
CATEGORY: Audio
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

This builds audio driver packages for ThinkPad machine types 21FA and 20QN.

### Example 2: Build All Critical Updates for a Model

```yaml
MODEL_LIST: ThinkPad X1 Carbon
MACHINE_TYPE: (leave empty)
UPDATE_TYPE: Driver
SEVERITY: Critical
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

This builds all critical driver packages for the ThinkPad X1 Carbon.

### Example 3: Build Specific Driver Categories

```yaml
MODEL_LIST: (leave empty)
MACHINE_TYPE: 21NY
UPDATE_TYPE: Driver
CATEGORY: Audio, Networking Wireless LAN, Display and Video Graphics
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

This builds only audio, wireless, and graphics driver packages for machine type 21NY.

### Example 4: Build BIOS Updates

```yaml
MODEL_LIST: (leave empty)
MACHINE_TYPE: 21FA
UPDATE_TYPE: Bios
OPERATING_SYSTEM: Win11
OUTPUT_DIRECTORY: C:\drivers
```

This builds BIOS update packages for machine type 21FA.

## ⏰ Scheduling Builds

You can configure the Jenkins job to run on a schedule using Jenkins cron syntax:

1. Open the job in Jenkins
2. Click "Configure"
3. Under "Build Triggers", enable "Build periodically"
4. Enter a cron expression:

### Common Cron Examples

```cron
# Run daily at 2 AM
H 2 * * *

# Run weekly on Sunday at 3 AM
H 3 * * 0

# Run monthly on the 1st at midnight
H 0 1 * *

# Run every 12 hours
H H/12 * * *
```

## 🐛 Troubleshooting

### Job Fails with "Module not found"

**Problem:** PowerShell modules are not available to the Jenkins agent.

**Solutions:**

- Install modules system-wide for all users:
  ```powershell
  Install-Module Chocolatey.Lenovo.DriverMgmt -Scope AllUsers -Force
  Install-Module Lenovo.Client.Scripting -Scope AllUsers -Force
  ```
- Verify module installation for Jenkins service account:
  ```powershell
  Get-Module -ListAvailable
  ```
- Check module paths:
  ```powershell
  $env:PSModulePath -split ';'
  ```

### Permission Denied When Creating Packages

**Problem:** Jenkins service account lacks permissions.

**Solutions:**

- Grant write permissions to `OUTPUT_DIRECTORY` for Jenkins service account
- Grant Jenkins service account permissions to execute Chocolatey commands
- Consider running Jenkins service as a domain account with appropriate permissions

### Jenkins Doesn't Show New Job

**Problem:** Job not appearing after installation.

**Solutions:**

- Verify Jenkins service restarted successfully:
  ```powershell
  Get-Service jenkins | Restart-Service
  ```
- Check job folder was created:
  ```powershell
  Test-Path "C:\ProgramData\Jenkins\.jenkins\jobs\Build Driver Package"
  ```
- Check Jenkins logs for errors:
  ```powershell
  Get-Content "C:\ProgramData\Jenkins\.jenkins\logs\*" -Tail 50
  ```

### Parameters Not Being Passed Correctly

**Problem:** PowerShell not receiving parameter values.

**Solutions:**

- Don't use quotes around parameter values unless required
- For comma-separated lists, use no spaces: `21FA,20QN` not `21FA, 20QN`
- Empty parameters are intentionally ignored - this is expected
- Check Jenkins build console output for parameter values being used

### Build Fails with Chocolatey Error

**Problem:** Chocolatey commands fail during package creation.

**Solutions:**

- Verify Chocolatey is installed for Jenkins service account:
  ```powershell
  choco --version
  ```
- Check Chocolatey logs: `C:\ProgramData\chocolatey\logs\chocolatey.log`
- Ensure Jenkins service account is in the local Administrators group
- Try running `choco` commands manually as Jenkins service account

## 🔒 Security Considerations

- **Service Account Permissions**: Grant Jenkins service account minimum required permissions
- **Output Directory**: Restrict write access to output directory to prevent unauthorized modifications
- **Credential Management**: Use Jenkins credentials plugin for any required authentication
- **Network Access**: Ensure Jenkins agent can reach Lenovo update servers

## 🔄 Modifying the Job

To modify job configuration:

### Option 1: Edit in Jenkins UI

1. Navigate to the job in Jenkins
2. Click "Configure"
3. Make changes in the web UI
4. Click "Save"

### Option 2: Edit config.xml and Reinstall

1. Edit `config.xml` file
2. Run `Install-Job.ps1` again with same job name (overwrites existing job)
3. Restart Jenkins

### Option 3: Jenkins Configuration as Code (JCasC)

For advanced users, consider using Jenkins Configuration as Code plugin to manage job configurations in version control.

## 📖 Additional Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [PowerShell Plugin for Jenkins](https://plugins.jenkins.io/powershell/)
- [Main Repository README](../README.md)
- [Lenovo Driver Management Documentation](../Lenovo/README.md)
- [Dell Driver Management Documentation](../Dell/README.md)
