<#
.SYNOPSIS
    Creates a Chocolatey meta package with specified dependencies.

.DESCRIPTION
    This script demonstrates how to create a Chocolatey meta package (a package with no actual files, 
    only dependencies on other packages). Meta packages are useful for grouping related packages together 
    or creating convenience packages that install multiple applications at once.
    
    The script uses the New-Metapackage function to generate a nuspec file with the specified dependencies,
    and optionally compiles it into a .nupkg file that can be pushed to a Chocolatey repository.

.PARAMETER Packages
    An array of hashtables where each hashtable represents a package dependency. 
    Each hashtable should contain 'id' and optionally 'version' keys.
    
    Example: @{id='firefox'; version='120.0'}, @{id='vlc'}

.PARAMETER Compile
    When specified, the script will compile the nuspec into a .nupkg file using choco pack.
    If not specified, only the nuspec file will be generated.

.EXAMPLE
    $deps = @(
        @{id='firefox'; version='120.0'}
        @{id='vlc'; version='3.0.20'}
        @{id='7zip'}
    )
    .\Example_Metapackage.ps1 -Packages $deps

    Creates a meta package with three dependencies. Firefox and VLC will install specific minimum versions,
    while 7zip will use the latest available version. Only generates the nuspec file.

.EXAMPLE
    .\Example_Metapackage.ps1 -Packages @(@{id='git'}, @{id='vscode'}) -Compile

    Creates a meta package with Git and VS Code dependencies, then compiles it into a .nupkg file.

.EXAMPLE
    $packages = @(
        @{id='googlechrome'}
        @{id='notepadplusplus'}
        @{id='putty'}
    )
    .\Example_Metapackage.ps1 -Packages $packages -Compile -Verbose

    Creates a compiled meta package with verbose output showing the dot-sourcing and creation process.

.NOTES
    Requires the New-Metapackage function to be available in the same directory.
    This function is automatically dot-sourced during script execution.
    
    The generated meta package will:
    - ID: example
    - Version: 1.0.0
    - Output Path: C:\webinar
    
    Modify the $newMetapackageSplat hashtable in the script to customize these values.

.LINK
    https://docs.chocolatey.org/en-us/create/create-packages#meta-packages
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [Hashtable[]]
    $Packages,

    [Parameter()]
    [Switch]
    $Compile
)

begin {
    Get-ChildItem $PSScriptRoot -Filter *-*.ps1 | Foreach-Object { 
        Write-Verbose "Dot-sourcing $($_.FullName)"
        . $_.FullName  
    }
}

process {
    $newMetapackageSplat = @{
        Id         = 'baseline'
        Summary    = 'This is a simple example'
        Description = 'This is a longer form description of the package'
        Dependency = $Packages
        Version    = '1.0.0'
        Path       = 'C:\webinar'
        Compile = $Compile.IsPresent
    }

    New-Metapackage @newMetapackageSplat
}
