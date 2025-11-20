function New-Dependency {
    <#
.SYNOPSIS
Injects <dependency> nodes into a Chocolatey package nuspec file

.DESCRIPTION
Adds package dependencies to a Chocolatey nuspec file by either providing hashtables with 
package IDs and versions, or by specifying nupkg filenames from which the package ID and 
version are extracted. Optionally recompiles the package after adding dependencies.

.PARAMETER Nuspec
The path to the Chocolatey package nuspec file to which dependencies will be added.

.PARAMETER Dependency
One or more hashtables containing dependency information. Each hashtable should have:
- id: The package ID of the dependency
- version: (Optional) The version or version range for the dependency

Supports NuGet version range syntax: https://learn.microsoft.com/en-us/nuget/concepts/package-versioning

.PARAMETER Nupkg
One or more nupkg filenames (e.g., 'package.1.2.3.nupkg') from which the package ID and 
version will be extracted automatically. The filename must follow the pattern: 
<packageid>.<version>.nupkg

.PARAMETER Recompile
When specified, recompiles the Chocolatey package after adding dependencies.

.PARAMETER OutputDirectory
Directory where the recompiled package will be saved. If not specified, saves to the 
same directory as the nuspec file.

.EXAMPLE
Add a single dependency with a version using a hashtable

New-Dependency -Nuspec C:\packages\foo.1.1.1.nuspec -Dependency @{id='baz'; version='3.4.2'}

.EXAMPLE
Add multiple dependencies using hashtables

New-Dependency -Nuspec C:\packages\foo.1.1.0.nuspec -Dependency @{id='baz'; version='1.1.1'},@{id='boo'; version='[1.0.1,2.9.0]'}

.EXAMPLE
Add dependencies from nupkg filenames

New-Dependency -Nuspec C:\packages\foo.1.1.1.nuspec -Nupkg 'n3tr503w.19.5.2.1049.nupkg','anotherpackage.2.0.1.nupkg'

.EXAMPLE
Add a dependency and recompile the package

$newDependencySplat = @{
    Nuspec = 'C:\packages\foo.1.1.1.nuspec'
    Dependency = @{id='baz'; version='3.4.2'}
    Recompile = $true
}

New-Dependency @newDependencySplat
        
.EXAMPLE
Add a dependency, recompile the package, and save it to a new location

$newDependencySplat = @{
    Nuspec = 'C:\packages\foo.1.1.1.nuspec'
    Dependency = @{id='baz'; version='3.4.2'}
    Recompile = $true
    OutputDirectory = 'C:\recompiled'
}

New-Dependency @newDependencySplat

.EXAMPLE
Add dependencies from nupkg files and recompile

New-Dependency -Nuspec C:\packages\myapp.1.0.0.nuspec -Nupkg 'dep1.2.3.4.nupkg','dep2.1.0.0.nupkg' -Recompile
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Nuspec,

        [Parameter(Mandatory, ParameterSetName = 'Dependency')]
        [Hashtable[]]
        $Dependency,

        [Parameter(Mandatory, ParameterSetName = 'Nupkg')]
        [String[]]
        $Nupkg,

        [Parameter()]
        [Switch]
        $Compile,

        [Parameter()]
        [String]
        [ValidateScript({ Test-Path $_ })]
        $OutputDirectory = (Split-Path -Parent $Nuspec)
    )

    process {
        [xml]$xmlContent = Get-Content $Nuspec

        # Define the XML namespace
        $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xmlContent.NameTable)
        $namespaceManager.AddNamespace("ns", "http://schemas.microsoft.com/packaging/2015/08/nuspec.xsd")

        # Check if the package node exists and verify its namespace
        $packageNode = $xmlContent.SelectSingleNode("//*[local-name()='package']", $namespaceManager)
        if ($null -eq $packageNode) {
            Write-Error "Package node not found. Exiting." -Category ObjectNotFound
            break
        }
        else {
            Write-Verbose "Package node found."
        }

        # Check if the metadata node exists within the package node
        $metadataNode = $xmlContent.SelectSingleNode("//*[local-name()='metadata']", $namespaceManager)
        if ($null -eq $metadataNode) {
            Write-Error "Metadata node not found." -Category ObjectNotFound
            break
        }
        else {
            Write-Verbose "Metadata node found."
        }

        # Find the dependencies node
        $dependenciesNode = $xmlContent.SelectSingleNode("//*[local-name()='dependencies']", $namespaceManager)

        if ($null -eq $dependenciesNode) {
            $null = $dependenciesNode = $xmlContent.CreateElement('dependencies')
            $null = $metadataNode.AppendChild($dependenciesNode)
        }
        else {
            Write-Verbose "Dependencies node found."
        }

        switch ($PSCmdlet.ParameterSetName) {
            'Dependency' {
                #Loop over the given dependencies and create new nodes for each
                foreach ($D in $Dependency) {
                    # Create a new XmlDocument
                    $newDoc = New-Object System.Xml.XmlDocument

                    # Create a new dependency element in the new document
                    $newDependency = $newDoc.CreateElement("dependency")
                    $newDependency.SetAttribute("id", "$($D['id'])")
                    if ($D.version) {

                        # Check if the version string contains invalid characters
                        # Valid ranges: https://learn.microsoft.com/en-us/nuget/concepts/package-versioning?tabs=semver20sort#version-ranges
                        if ($($D['version']) -match '\([^,]*?\)') {
                            Write-Error "Invalid version string: $($D['version']) for package $($D['id'])"
                            continue
                        }
                        $newDependency.SetAttribute("version", "$($D['version'])")
                    }
                    # Import the new dependency into the original document
                    $importedDependency = $xmlContent.ImportNode($newDependency, $true)

                    # Append the imported dependency to the dependencies node
                    $null = $dependenciesNode.AppendChild($importedDependency)
                }
            }

            'Nupkg' {
                foreach ($N in $Nupkg) {

                    $null = $N -match '^(?<dependencyid>[^.]+)(?=\.)\.(?<dependencyversion>.+?)\.nupkg$'
                    $DependencyId, $DependencyVersion = $matches.dependencyid, $matches.dependencyversion
                    # Create a new XmlDocument
                    $newDoc = New-Object System.Xml.XmlDocument

                    # Create a new dependency element in the new document
                    $newDependency = $newDoc.CreateElement("dependency")
                    $newDependency.SetAttribute("id", "$DependencyId")
                    if ($DependencyVersion) {

                        # Check if the version string contains invalid characters
                        # Valid ranges: https://learn.microsoft.com/en-us/nuget/concepts/package-versioning?tabs=semver20sort#version-ranges
                        if ($DependencyVersion -match '\([^,]*?\)') {
                            Write-Error "Invalid version string: $DependencyVersion for package $DependencyId"
                            continue
                        }

                        $newDependency.SetAttribute("version", "$DependencyVersion")
                    }
                    # Import the new dependency into the original document
                    $importedDependency = $xmlContent.ImportNode($newDependency, $true)

                    # Append the imported dependency to the dependencies node
                    $null = $dependenciesNode.AppendChild($importedDependency)
                }
            }
        }

        # Save the xml back to the nuspec file
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Indent = $true
        $settings.Encoding = [System.Text.Encoding]::UTF8

        $writer = [System.Xml.XmlWriter]::Create($Nuspec, $settings)
        try {
            $xmlContent.WriteTo($writer)
        }
        finally {
            $writer.Flush()
            $writer.Close()
            $writer.Dispose()
        }

        # Stupid hack to get rid of the 'xlmns=' part of the new dependency nodes. .Net methods are "overly helpful"
        $content = Get-Content -Path $Nuspec -Raw
        $content = $content -replace ' xmlns=""', ''
        Set-Content -Path $Nuspec -Value $content

        if ($Compile) {
            if (-not (Get-Command choco)) {
                Write-Error "Choco is required to recompile the package but was not found on this system" -Category ResourceUnavailable
            }
            else {
                $OD = if ($OutputDirectory) {
                    $OutputDirectory
                }
                else {
                    Split-Path -Parent $Nuspec
                }

                $chocoArgs = ('pack', $Nuspec, "--output-directory='$OD'")
                $choco = (Get-Command choco).Source
                & $choco @chocoArgs

                if ($LASTEXITCODE -eq 0) {
                    'Package is ready and available at {0}' -f $OD
                }
                else {
                    throw 'Recompile had an error, see chocolatey.log for details'
                }
            }
        }
    }
}