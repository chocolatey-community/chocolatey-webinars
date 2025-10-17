<#
.SYNOPSIS
    Creates a dependency tree for ordered Chocolatey package installation.

.DESCRIPTION
    This script builds a dependency chain across multiple Chocolatey packages to ensure they install in a specific order.
    It creates a dependency tree where the meta package depends on the first package, and each subsequent package 
    depends on the next one in the ordered dictionary.
    
    The dependency chain works as follows:
    - MetaNuspec depends on the first package in Dependencies
    - First package depends on second package
    - Second package depends on third package
    - And so on...
    
    This ensures that when the meta package is installed, Chocolatey will install all dependencies in reverse order,
    resulting in the desired installation sequence.

.PARAMETER MetaNuspec
    The path to the meta package nuspec file that will depend on the first package in the dependency chain.

.PARAMETER Dependencies
    An OrderedDictionary where each key is a package name and each value is the path to that package's nuspec file.
    The order of items in this dictionary determines the installation order.

.EXAMPLE
    $deps = [ordered]@{
        Firefox = "C:\webinar\packages\Firefox\Firefox.nuspec"
        Putty   = "C:\webinar\packages\putty.portable\putty.portable.nuspec"
        VLC     = "C:\webinar\packages\vlc.install\vlc.install.nuspec"
    }
    .\Example_OrderedInstall.ps1 -MetaNuspec "C:\packages\myapp\myapp.nuspec" -Dependencies $deps

    This creates a dependency chain: myapp -> Firefox -> Putty -> VLC
    Installation order will be: VLC, then Putty, then Firefox, then myapp

.EXAMPLE
    .\Example_OrderedInstall.ps1 -MetaNuspec "C:\meta.nuspec" -Dependencies ([ordered]@{
        "package1" = "C:\pkg1\pkg1.nuspec"
        "package2" = "C:\pkg2\pkg2.nuspec"
    }) -Verbose

    Creates a simple two-package dependency chain with verbose output.

.NOTES
    Requires the New-Dependency and Convert-Xml functions to be available in the same directory.
    These functions are automatically dot-sourced during script execution.

.LINK
    https://docs.chocolatey.org/en-us/create/create-packages
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $MetaNuspec,

    [Parameter(Mandatory)]
    [System.Collections.Specialized.OrderedDictionary]
    $Dependencies

)

begin {
    # Load the functions from the current directory so we can use them in our session
    # ensuring we only load the files with functions to prevent a loop
    Get-ChildItem $PSScriptRoot -Filter *-*.ps1 | Foreach-Object { 
        Write-Verbose "Dot-sourcing $($_.FullName)"
        . $_.FullName  
    }
}

process {

    $keys = @($Dependencies.Keys)

    $firstSpec = $Dependencies[$keys[0]]
    $first = Convert-Xml $firstSpec
    $dependency = @{id = $first.id ; version = $first.version }
    New-Dependency -Nuspec $MetaNuspec -Dependency $dependency

    for ( $i = 0; $i -lt $keys.Count ; $i ++) {

        if ($i -ne ($keys.Count - 1)) {
            $currentSpec = $Dependencies[$keys[$i]]
            $nextSpec = $Dependencies[$keys[$i + 1]]
            $next = Convert-Xml $nextSpec
            $dependency = @{id = $next.id ; version = $next.version }
            New-Dependency -Nuspec $currentSpec -Dependency $dependency
        }
    }
}
