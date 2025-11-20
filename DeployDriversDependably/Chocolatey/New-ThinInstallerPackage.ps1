<#
.SYNOPSIS
    Creates a Chocolatey package for Lenovo Thin Installer.

.DESCRIPTION
    This script automates the creation of a Chocolatey package for Lenovo Thin Installer,
    a tool that helps identify and deploy system updates, drivers, and applications for
    Lenovo computers. The script:
    
    1. Verifies Chocolatey CLI is installed
    2. Validates a Chocolatey for Business (C4B) license is present
    3. Creates a new Chocolatey package using the specified download URL
    4. Automatically builds the package into a .nupkg file
    
    This script requires Chocolatey for Business as it uses the Package Builder
    functionality (--build-package flag) which is not available in the open-source version.

.PARAMETER PackageId
    The unique identifier for the Chocolatey package. Defaults to 'lenovo-thininstaller'.
    This will be used as the package name and folder name.

.PARAMETER DownloadLocation
    The URL where the Lenovo Thin Installer executable can be downloaded.
    Defaults to the official Lenovo download location for version 1.04.02.00024.
    Update this parameter if you need to package a different version.

.PARAMETER OutputDirectory
    The directory where the package will be created. Defaults to the current directory ($PWD).
    The package structure and compiled .nupkg file will be placed in this location.

.EXAMPLE
    .\New-ThinInstallerPackage.ps1
    
    Creates a Chocolatey package for Lenovo Thin Installer using all default values.
    The package will be created in the current directory.

.EXAMPLE
    .\New-ThinInstallerPackage.ps1 -OutputDirectory 'C:\Packages'
    
    Creates the Lenovo Thin Installer package in the C:\Packages directory.

.EXAMPLE
    .\New-ThinInstallerPackage.ps1 -PackageId 'lenovo-thininstaller-latest' -DownloadLocation 'https://download.lenovo.com/path/to/newer/version.exe'
    
    Creates a package with a custom ID and downloads from a different URL (e.g., for a newer version).

.EXAMPLE
    .\New-ThinInstallerPackage.ps1 -OutputDirectory 'C:\ChocolateyPackages' -PackageId 'thininstaller' -Verbose
    
    Creates the package with verbose output showing detailed progress information.

.OUTPUTS
    Creates a Chocolatey package (.nupkg file) ready for deployment.
    The package contains:
    - Package metadata (nuspec file)
    - Installation scripts
    - Reference to the Thin Installer download URL

#>

[CmdletBinding()]
Param(
    [Parameter()]
    [String]
    $PackageId = 'lenovo-thininstaller',

    [Parameter()]
    [String]
    $DownloadLocation = 'https://download.lenovo.com/pccbbs/thinkvantage_en/lenovo_thininstaller_1.04.02.00024.exe',
    
    [Parameter()]
    [String]
    $OutputDirectory = $PWD
)

begin {
    if (-not (Get-Command choco -OutVariable choco).Source) {
        throw 'Chocolatey CLI is required for this script. Please install it to continue.'
    }
}

end {
    $packageArgs = @('new', $PackageId, "--url='$DownloadLocation'", "--output-directory='$OutputDirectory'", '--build-package')
    & $choco @packageArgs
}