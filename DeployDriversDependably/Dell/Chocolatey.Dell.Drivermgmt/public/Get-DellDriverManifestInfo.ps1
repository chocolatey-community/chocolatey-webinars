function Get-DellDriverManifestInfo {
    <#
.SYNOPSIS
   Parses Dell driver pack Manifest.xml files and extracts driver metadata.

.DESCRIPTION
   Reads a Dell driver pack Manifest.xml file and returns structured information
   about the drivers, including system details, OS info, and driver releases
   organized by category.

.PARAMETER ManifestPath
   Path to the Dell Manifest.xml file from an extracted driver pack.

.EXAMPLE
   Get-DellDriverManifestInfo -ManifestPath ".\repo\Latitude 5420\5420-win10-A10-7PYRM\5420\Manifest.xml"

.EXAMPLE
   $manifest = Get-DellDriverManifestInfo -ManifestPath ".\repo\Latitude 5420\5420-win10-A10-7PYRM\5420\Manifest.xml"
   $manifest.Releases | Where-Object { $_.Category -eq 'video' }
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ 
            if (Test-Path $_ -PathType Leaf) { 
                return $true 
            } else { 
                throw "File not found: $_" 
            }
        })]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [string[]]$Category
    )

    # Load the manifest XML
    Write-Verbose "Loading manifest from: $ManifestPath"
    
    # Resolve to absolute path
    $ManifestPath = (Resolve-Path -Path $ManifestPath).Path
    [xml]$Manifest = Get-Content -Path $ManifestPath

    # Get the base path where drivers are located (parent of Manifest.xml)
    $DriverBasePath = Split-Path -Parent $ManifestPath

    # Extract system information
    $SystemInfo = [PSCustomObject]@{
        Model = $Manifest.Catalog.System.Model
        SystemID = $Manifest.Catalog.System.SystemID
        LOB = $Manifest.Catalog.System.LOB
        OSName = $Manifest.Catalog.System.OS.Name
        OSArch = $Manifest.Catalog.System.OS.Arch
        OSMajorVersion = $Manifest.Catalog.System.OS.MajorVersion
        OSMinorVersion = $Manifest.Catalog.System.OS.MinorVersion
        OSType = $Manifest.Catalog.System.OS.Type
        Version = $Manifest.Catalog.Version
        ReleaseID = $Manifest.Catalog.ReleaseID
        CreateDate = $Manifest.Catalog.CreateDate
        Application = $Manifest.Catalog.Application
        ApplicationVersion = $Manifest.Catalog.ApplicationVersion
    }

    Write-Verbose "System Model: $($SystemInfo.Model)"
    Write-Verbose "OS: $($SystemInfo.OSName) $($SystemInfo.OSArch)"
    Write-Verbose "Version: $($SystemInfo.Version)"

    # Parse all driver releases
    $Releases = @()
    foreach ($Release in $Manifest.Catalog.System.OS.Release) {
        # Filter by category if specified
        if ($Category -and $Release.Category -notin $Category) {
            continue
        }

        $Packages = @()
        foreach ($Package in $Release.Package) {
            # The SrcPath in Dell manifests includes the model folder (e.g., "5420\win10\...") 
            # but the actual files are relative to the DriverBasePath without that prefix
            # Strip the first path component (model folder) from SrcPath
            $srcPathParts = $Package.SrcPath -split '\\'
            if ($srcPathParts.Count -gt 1) {
                $relativePath = $srcPathParts[1..($srcPathParts.Count - 1)] -join '\'
            } else {
                $relativePath = $Package.SrcPath
            }
            
            # Resolve full source path to absolute path
            $fullSourcePath = Join-Path $DriverBasePath $relativePath
            if (Test-Path $fullSourcePath) {
                $fullSourcePath = (Resolve-Path -Path $fullSourcePath).Path
            }
            
            $Packages += [PSCustomObject]@{
                DestPath = $Package.DestPath
                SrcPath = $Package.SrcPath
                FullSourcePath = $fullSourcePath
            }
        }

        $Releases += [PSCustomObject]@{
            ReleaseID = $Release.ReleaseID
            ReleaseType = $Release.ReleaseType
            Category = $Release.Category
            DeviceDescription = $Release.DeviceDescription
            DellVersion = $Release.DellVersion
            VendorVersion = $Release.VendorVersion
            PackageCount = $Packages.Count
            Packages = $Packages
        }
    }

    # Group releases by category for easy access
    $Categories = $Releases | Group-Object -Property Category | ForEach-Object {
        [PSCustomObject]@{
            Category = $_.Name
            ReleaseCount = $_.Count
            Releases = $_.Group
        }
    }

    # Return structured manifest information
    [PSCustomObject]@{
        ManifestPath = $ManifestPath
        DriverBasePath = $DriverBasePath
        SystemInfo = $SystemInfo
        Releases = $Releases
        Categories = $Categories
        TotalReleases = $Releases.Count
        TotalPackages = ($Releases | Measure-Object -Property PackageCount -Sum).Sum
    }
}
