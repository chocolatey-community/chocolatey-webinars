function New-DellDriverPackage {
    <#
    .SYNOPSIS
        Creates a Chocolatey package for Dell drivers.
    
    .DESCRIPTION
        Generates Chocolatey packages for Dell drivers using different methods:
        - From a remote driver pack URL
        - From a local driver pack file
        - From an extracted manifest with optional category filtering
        - From Dell Command Update repository
    
    .PARAMETER PackageId
        The Chocolatey package ID. Must end with '.driver'.
    
    .PARAMETER Version
        The package version. Defaults to current date in yyyy.MM.dd format.
    
    .PARAMETER Metadata
        Path to a Dell Manifest.xml file from an extracted driver pack. Used with 'delldriver' template.
    
    .PARAMETER Category
        Optional array of driver categories to include when using a manifest. Examples: 'audio', 'video', 'network'.
    
    .PARAMETER DriverPack
        URL or local path to a Dell driver pack EXE file. Used with 'delldriverpack' template.
    
    .PARAMETER DriverRepository
        Path to a Dell Command Update driver repository. Used with 'delldcu' template.
    
    .PARAMETER OutputDirectory
        Directory where the package will be created. Defaults to current directory.
    
    .PARAMETER Template
        The Chocolatey template to use: 'delldriver', 'delldriverpack', or 'delldcu'.
    
    .PARAMETER Compile
        If specified, compiles the package to a .nupkg file after creation.
    
    .EXAMPLE
        New-DellDriverPackage -PackageId 'dell-latitude7450.driver' -DriverPack 'https://example.com/driver.exe' -Template 'delldriverpack' -Compile
        
        Creates a package from a remote driver pack URL.
    
    .EXAMPLE
        New-DellDriverPackage -PackageId 'dell-latitude5420audio.driver' -Metadata '.\Manifest.xml' -Category 'audio','chipset' -Template 'delldriver' -Compile
        
        Creates a package from a manifest, including only audio and chipset drivers.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({ $_ -match '\.driver$' })]
        [String]
        $PackageId,

        [Parameter()]
        [String]
        $Version = (Get-Date -Format 'yyyy.MM.dd'),

        [Parameter(Mandatory, ParameterSetName = 'delldriver')]
        [string]
        $Metadata,

        [Parameter(ParameterSetName = 'delldriver')]
        [String[]]
        $Category,

        [Parameter(Mandatory, ParameterSetName = 'delldriverpack')]
        [String]
        $DriverPack,

        [Parameter(Mandatory, ParameterSetName = 'delldcu')]
        [String]
        $DriverRepository,

        [Parameter()]
        [String]
        $OutputDirectory = $PWD,

        [Parameter()]
        [ValidateSet('delldriver', 'delldriverpack', 'delldcu')]
        [String]
        $Template = 'delldriver',

        [Parameter()]
        [Switch]
        $Compile
    )

    begin {
        $choco = (Get-Command choco).Source

        if (-not $choco) {
            throw 'Chocolatey is required to run this command and cannot be found on the system.'
        }
        
        if ($DriverPack -and $DriverPack -notmatch '^https?://') {
            if (-not (Test-Path $DriverPack)) {
                throw "Driver pack file not found: $DriverPack"
            }
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
        $chocoArgs.Add("--output-directory='$OutputDirectory'")
        $chocoArgs.Add("Title='A title'")

        # Get the package tools folder (used by all templates)
        $packageFolder = Join-Path $OutputDirectory -ChildPath "$packageId\tools"

        switch ($Template) {
            'delldriver' {
                $chocoArgs.Add("--template='delldriver'")

                & $choco @chocoArgs
                $chocoArgs.Clear()

                # Then get the Repository folder to hold our drivers
                $driverFolder = Join-Path $packageFolder -ChildPath 'repository'

                # Create driver folder if it doesn't exist
                if (!(Test-Path $driverFolder)) {
                    New-Item -Path $driverFolder -ItemType Directory -Force | Out-Null
                }

                # Parse the Dell manifest to get driver metadata
                Write-Verbose "Parsing Dell driver manifest: $Metadata"
                if ($Category) {
                    $manifestInfo = Get-DellDriverManifestInfo -ManifestPath $Metadata -Category $Category
                }
                else {
                    $manifestInfo = Get-DellDriverManifestInfo -ManifestPath $Metadata
                }

                Write-Verbose "System: $($manifestInfo.SystemInfo.Model)"
                Write-Verbose "Total Releases: $($manifestInfo.TotalReleases)"
                Write-Verbose "Total Packages: $($manifestInfo.TotalPackages)"

                # Copy all driver packages organized by category
                foreach ($release in $manifestInfo.Releases) {
                    Write-Verbose "Processing release: $($release.ReleaseID) - $($release.DeviceDescription) [$($release.Category)]"
            
                    # Create category folder
                    $categoryFolder = Join-Path $driverFolder $release.Category
                    if (!(Test-Path $categoryFolder)) {
                        New-Item -Path $categoryFolder -ItemType Directory -Force | Out-Null
                    }
            
                    foreach ($package in $release.Packages) {
                        $sourceFile = $package.FullSourcePath
                        $fileName = Split-Path -Leaf $package.DestPath
                        $destFile = Join-Path $categoryFolder $fileName

                        # Copy the driver file
                        if (Test-Path $sourceFile) {
                            Copy-Item -Path $sourceFile -Destination $destFile -Force
                            Write-Verbose "  Copied to $($release.Category): $fileName"
                        }
                        else {
                            Write-Warning "Source file not found: $sourceFile"
                        }
                    }
                }
            }
            
            'delldriverpack' {
                $pack = Split-Path -Leaf $DriverPack

                if ($DriverPack -match '^https?://') {
                    # URL logic
                    $chocoArgs.Add("--template='delldriverpack'")
                    $assetDir = Split-Path (Split-Path $DriverPack) -leaf
                    $AssetMetadata = Get-ProGetAssetItemMetadata -AssetDirectory $assetDir -Path $pack
                    $chocoArgs.Add("URL='$DriverPack'")
                    $chocoArgs.Add("CHECKSUM='$($AssetMetadata.Sha256)'")

                    & $choco @chocoArgs
                    $chocoArgs.Clear()
                }
                else {
                    # Local file logic
                    $chocoArgs.Add("--template='delldriverpacklocal'")
                    $chocoArgs.Add("URL='$pack'")
                    $checksum = (Get-FileHash $DriverPack).Hash
                    $chocoArgs.Add("CHECKSUM='$checksum'")

                    & $choco @chocoArgs
                    $chocoArgs.Clear()
                
                    Copy-Item $DriverPack -Destination $packageFolder
                }
                
                & $choco @chocoArgs
                $chocoArgs.Clear()

            }
            'delldcu' {
                $chocoArgs.Add("--template='delldcu'")
                
                & $choco @chocoArgs
                $chocoArgs.Clear()

                # Then get the Repository folder to hold our drivers
                $driverFolder = Join-Path $packageFolder -ChildPath 'repository'

                # Copy drivers to package repository folder
                Copy-Item -Path $DriverRepository -Destination $driverFolder -Force
            }
        }

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