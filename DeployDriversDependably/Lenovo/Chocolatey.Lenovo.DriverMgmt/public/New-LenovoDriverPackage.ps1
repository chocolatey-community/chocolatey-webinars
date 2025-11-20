class VersionTransform : System.Management.Automation.ArgumentTransformationAttribute {
    [object] Transform([System.Management.Automation.EngineIntrinsics]$engineIntrinsics, [object]$inputData) {
        if ($inputData -is [string] -and $inputData -match '/') {
            return ($inputData -split '/')[0]
        }
        return $inputData
    }
}

function New-LenovoDriverPackage {
    <#
.SYNOPSIS
    Creates a Chocolatey package containing Lenovo driver updates.

.DESCRIPTION
    This script automates the creation of a Chocolatey package for Lenovo drivers by:
    1. Generating a new Chocolatey package structure from a template
    2. Creating a repository folder to store driver files
    3. Downloading driver installers and their XML descriptors
    4. Optionally compiling the package into a .nupkg file
    
    The script displays progress while downloading drivers and organizes them by driver ID
    within the package structure. Each driver gets its own subfolder containing the installer
    and descriptor XML file.

.PARAMETER PackageId
    The unique identifier for the Chocolatey package (e.g., 'lenovo-t14-drivers').
    This parameter is mandatory and will be used as the package name.

.PARAMETER UpdateData
    An array of update objects containing driver information. Each object should have:
    - Name: Display name of the driver
    - ID: Unique identifier for the driver
    - Descriptor: URL to the driver's XML descriptor file
    - PackageExe: URL to the driver installer executable
    
    Typically obtained from Get-AvailableLenovoDriver or Find-LnvUpdate cmdlets.

.PARAMETER Template
    The Chocolatey template to use for package generation. Default is 'lenovo'.
    This template should be available in your Chocolatey templates directory.

.PARAMETER OutputDirectory
    The directory where the package will be created. Defaults to the current directory ($PWD).
    The package folder structure will be created as a subfolder within this directory.

.PARAMETER Version
    The version number for the package in yyyy.MM.dd format.
    Defaults to the current date (e.g., '2025.11.05').

.PARAMETER Title
    The display title for the package. Defaults to "Lenovo driver bundle for YYYY-MM"
    based on the version parameter.

.PARAMETER Compile
    When specified, the script will compile the package into a .nupkg file after
    downloading all drivers. Without this switch, only the package structure is created.

.EXAMPLE
    $updates = Get-AvailableLenovoDriver -MachineType 21FA -UpdateType Driver
    .\New-LenovoDriverPackage.ps1 -PackageId 'lenovo-t14-drivers' -UpdateData $updates
    
    Creates a package structure with drivers for a Lenovo T14, but does not compile it.

.EXAMPLE
    $updates = Find-LnvUpdate -MachineType 21FA -ListAll
    .\New-LenovoDriverPackage.ps1 -PackageId 'lenovo-drivers' -UpdateData $updates -Compile
    
    Creates and compiles a complete driver package with all available updates.

.EXAMPLE
    .\New-LenovoDriverPackage.ps1 -PackageId 'lenovo-x1carbon' -UpdateData $drivers -Version '2025.11.05' -OutputDirectory 'C:\Packages' -Compile -Verbose
    
    Creates a versioned driver package in a specific directory with verbose output and compilation.

.EXAMPLE
    $drivers = Get-AvailableLenovoDriver -MachineType 21HM -UpdateType Driver -OperatingSystem Win11
    .\New-LenovoDriverPackage.ps1 -PackageId 'lenovo-x1carbon-win11' -UpdateData $drivers -Title 'X1 Carbon Win11 Drivers' -Compile
    
    Creates a Windows 11 driver package for X1 Carbon with a custom title.

.OUTPUTS
    None
    The script creates a package directory structure and optionally a .nupkg file.
    Progress information is displayed during driver downloads.

.NOTES
    Author: [Your Name]
    Date: November 5, 2025
    Version: 1.0
    
    Requirements:
    - Chocolatey must be installed
    - Internet connection for downloading drivers
    - Sufficient disk space for driver files
    - Lenovo driver template must be available
    
    Package Structure Created:
    <PackageId>/
    ├── <PackageId>.nuspec
    └── tools/
        ├── chocolateyinstall.ps1
        ├── chocolateyuninstall.ps1
        └── Repository/
            ├── <DriverID1>/
            │   ├── descriptor.xml
            │   └── installer.exe
            └── <DriverID2>/
                ├── descriptor.xml
                └── installer.exe
    
    The script uses Write-Progress to show download status, which can be suppressed
    with $ProgressPreference = 'SilentlyContinue' if needed.
#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $PackageId,

        [Parameter()]
        [PSObject[]]
        $UpdateData,

        [Parameter()]
        [String]
        $Template = 'lenovo',

        [Parameter()]
        [String]
        $OutputDirectory = $PWD,

        [Parameter()]
        [VersionTransform()]
        [String]
        $Version = $UpdateData.Version,

        [Parameter()]
        [String]
        $Title = $($UpdateData.Name),

        [Parameter()]
        [Switch]
        $Compile
    )

    begin {
        $choco = (Get-Command choco).Source

        if (-not $choco) {
            throw 'Chocolatey is required to run this command and cannot be found on the system.'
        }
    }
    process {

        # Generate our Chocolatey package
        Write-Verbose "Generating driver package"
        $chocoArgs = [System.Collections.Generic.List[string]]::new()
        $chocoArgs.Add('new')
        $chocoArgs.Add($PackageId)
        $chocoArgs.Add("--version='$Version'")
        $chocoArgs.Add("--maintainer='$env:Username")
        $chocoArgs.Add("--template='$Template'")
        $chocoArgs.Add("--output-directory='$OutputDirectory'")
        $chocoArgs.Add("Title='$Title'")

        & $choco @chocoArgs
        $chocoArgs.Clear()

        # Get the package tools folder
        $packageFolder = Join-Path $OutputDirectory -ChildPath "$packageId\tools"

        # Then create the Repository folder to hold our drivers
        $repositoryFolder = New-Item -Path $packageFolder -Name 'Repository' -ItemType Directory

        # Download drivers into package
        Write-Verbose "Adding drivers to package"
        $totalDrivers = $UpdateData.Count
        $currentDriver = 0
        
        foreach ($Update in $UpdateData) {
            # Get data needed from Object
            $Name = $Update.Name
            $ID = $Update.ID
            $Descriptor = $Update.Descriptor
            $Driver = $Update.PackageExe

            $currentDriver++
            $percentComplete = ($currentDriver / $totalDrivers) * 100
            
            Write-Progress -Activity "Adding drivers to package" `
                -Status "Processing: $Name ($currentDriver of $totalDrivers)" `
                -PercentComplete $percentComplete `
                -CurrentOperation "Downloading driver files for $ID"

            #Create folder for driver
            $driverFolder = New-Item -Path $repositoryFolder -Name $ID -ItemType Directory

            # Download Descriptor to drive folder
            Write-Progress -Activity "Adding drivers to package" `
                -Status "Processing: $Name ($currentDriver of $totalDrivers)" `
                -PercentComplete $percentComplete `
                -CurrentOperation "Downloading descriptor: $(Split-Path -Leaf $Descriptor)"
            
            $descriptorXml = Join-Path $driverFolder -ChildPath (Split-Path -Leaf $Descriptor)
            [System.Net.WebClient]::new().DownloadFile($Descriptor, $descriptorXml)

            # Download Driver installer to driver folder
            Write-Progress -Activity "Adding drivers to package" `
                -Status "Processing: $Name ($currentDriver of $totalDrivers)" `
                -PercentComplete $percentComplete `
                -CurrentOperation "Downloading installer: $(Split-Path -Leaf $Driver)"
            
            $driverInstaller = Join-Path $driverFolder -ChildPath (Split-Path -Leaf $Driver)
            [System.Net.WebClient]::new().DownloadFile($Driver, $driverInstaller)
        }
        
        # Clear the progress bar when done
        Write-Progress -Activity "Adding drivers to package" -Completed
        
        # Compile Chocolatey package if requested
        if ($Compile) {
            Write-Verbose "Compile requested, starting..."
            $nuspec = Join-Path (Split-Path -Parent $packageFolder) -ChildPath "$PackageId.nuspec"
            $chocoArgs.Add('pack')
            $chocoArgs.Add($nuspec)
            $chocoArgs.Add("--output-directory='$OutputDirectory'")

            & $choco @chocoArgs
        }

        Write-Verbose "Finished. Find package at: $OutputDirectory"
    }
}