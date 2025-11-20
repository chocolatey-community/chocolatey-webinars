function Get-LenovoDriverInstallInfo {
    <#
    .SYNOPSIS
        Extracts installation information from a Lenovo driver descriptor XML file.
    
    .DESCRIPTION
        This function parses a Lenovo driver package descriptor XML file and returns
        structured information about how to extract and install the driver, including
        the executable paths and silent installation arguments.
        
        The function processes the ExtractCommand and Install/Cmdline nodes from the XML
        to provide extract and installation commands with proper argument separation.
    
    .PARAMETER DescriptorPath
        The path to the Lenovo driver descriptor XML file (typically named like n3trg05w_2_.xml).
        This file is included in driver packages downloaded from Lenovo.
    
    .PARAMETER PackagePath
        The directory path where the driver package files are located. This will be used
        to replace the %PACKAGEPATH% placeholder in the XML commands. If not specified,
        uses the parent directory of the descriptor file.
    
    .EXAMPLE
        Get-LenovoDriverInstallInfo -DescriptorPath "C:\Drivers\n3trg05w\n3trg05w_2_.xml"
        
        Extracts installation information from the specified descriptor file.
        Output:
        PackageId              : n3trg05w
        PackageName            : IMEFW_N3TRG
        Version                : 16.1.38.2676
        ExtractExecutable      : n3trg05w.exe
        ExtractSilentArgs      : /VERYSILENT /DIR=C:\Drivers\n3trg05w /EXTRACT="YES"
        InstallerCommand       : C:\Drivers\n3trg05w\fwcapupdate_v47.exe
        InstallerSilentArgs    : /silent
        RebootType             : 5
        
    .EXAMPLE
        $info = Get-LenovoDriverInstallInfo -DescriptorPath ".\n3trg05w_2_.xml" -PackagePath "C:\CustomPath"
        & $info.ExtractExecutable $info.ExtractSilentArgs.Split(' ')
        
        Gets the installation info and uses it to extract the driver package.
    
    .EXAMPLE
        Get-ChildItem "C:\Drivers" -Recurse -Filter "*_2_.xml" | ForEach-Object {
            Get-LenovoDriverInstallInfo -DescriptorPath $_.FullName
        }
        
        Processes all Lenovo driver descriptor XML files in the Drivers directory.
    
    .OUTPUTS
        PSCustomObject with the following properties:
        - PackageId: The unique package identifier
        - PackageName: The descriptive package name
        - Version: The package version
        - ExtractExecutable: The executable used to extract the package
        - ExtractSilentArgs: Silent arguments for extraction
        - InstallerCommand: The full path to the installer executable
        - InstallerSilentArgs: Silent arguments for installation
        - RebootType: The reboot type code (1=Forced, 3=Required, 4=Shutdown, 5=Delayed)
    
    .NOTES
        Author: [Your Name]
        Date: November 14, 2025
        Version: 1.0
        
        Reboot Type Codes:
        - 1: Forced reboot - Update itself initiates the reboot
        - 3: Requires reboot - Thin Installer/System Update/CV initiates the reboot
        - 4: Forces shutdown - Update itself initiates shutdown
        - 5: Delayed forced reboot - Used for firmware, with countdown timer
        
        The %PACKAGEPATH% placeholder in the XML is replaced with the actual package directory.
    
    .LINK
        Get-AvailableLenovoDriver
    
    .LINK
        New-LenovoDriverPackage
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateScript({
                if (-not (Test-Path $_)) {
                    throw "Descriptor file not found: $_"
                }
                if ([System.IO.Path]::GetExtension($_) -ne '.xml') {
                    throw "File must be an XML file: $_"
                }
                return $true
            })]
        [string]$DescriptorPath,
        
        [Parameter()]
        [string]$PackagePath
    )
    
    process {
        try {
            # Resolve full path
            $DescriptorPath = Resolve-Path $DescriptorPath -ErrorAction Stop
            
            # Determine package path if not provided
            if (-not $PackagePath) {
                $PackagePath = Split-Path -Parent $DescriptorPath
            }
            
            Write-Verbose "Loading descriptor XML from: $DescriptorPath"
            [xml]$descriptor = Get-Content -Path $DescriptorPath -ErrorAction Stop
            
            # Get package information
            $package = $descriptor.Package
            $packageId = $package.id
            $packageName = $package.name
            $version = $package.version
            
            Write-Verbose "Processing package: $packageName ($packageId) v$version"
            
            # Process ExtractCommand
            $extractCommand = $package.ExtractCommand
            if (-not $extractCommand) {
                Write-Warning "No ExtractCommand found in descriptor"
                $extractExecutable = $null
                $extractArgs = $null
            }
            else {
                # Replace %PACKAGEPATH% placeholder
                $extractCommand = $extractCommand -replace '%PACKAGEPATH%', $PackagePath
                
                # Split into executable and arguments
                # Pattern: executable.exe followed by arguments
                if ($extractCommand -match '^(.+?\.exe)\s+(.+)$') {
                    $extractExecutable = Join-Path $PackagePath -ChildPath $matches[1].Trim()
                    $extractArgs = $matches[2].Trim()
                }
                elseif ($extractCommand -match '^(.+?\.exe)$') {
                    $extractExecutable = Join-Path $PackagePath -ChildPath $matches[1].Trim()
                    $extractArgs = ""
                }
                else {
                    Write-Warning "Could not parse ExtractCommand: $extractCommand"
                    $extractExecutable = $extractCommand
                    $extractArgs = ""
                }
            }
            
            # Process Install Command
            $installNode = $package.Install
        
            # Try to get the command from CDATA section first
            if ($installNode.Cmdline.'#cdata-section') {
                $installCommand = $installNode.Cmdline.'#cdata-section'
            }
            # Otherwise get the text content
            elseif ($installNode.Cmdline.'#text') {
                $installCommand = $installNode.Cmdline.'#text'
            }
            # Fallback to InnerText
            elseif ($installNode.Cmdline.InnerText) {
                $installCommand = $installNode.Cmdline.InnerText
            }
            else {
                $installCommand = $null
            }
            
            if (-not $installCommand) {
                Write-Warning "No Install command found in descriptor"
                $installerCommand = $null
                $installerArgs = $null
            }
            else {
                # Replace %PACKAGEPATH% placeholder
                $installCommand = $installCommand -replace '%PACKAGEPATH%', $PackagePath
                
                # Split into executable and arguments
                if ($installCommand -match '^(.+?\.exe)\s+(.+)$') {
                    $installerCommand = $matches[1].Trim()
                    $installerArgs = $matches[2].Trim()
                }
                elseif ($installCommand -match '^(.+?\.exe)$') {
                    $installerCommand = $matches[1].Trim()
                    $installerArgs = ""
                }
                else {
                    Write-Warning "Could not parse Install command: $installCommand"
                    $installerCommand = $installCommand
                    $installerArgs = ""
                }
            }
            
            # Get reboot type
            $rebootType = $package.Reboot.type
            
            # Create and return the result object
            [PSCustomObject]@{
                PSTypeName          = 'LenovoDriverInstallInfo'
                PackageId           = $packageId
                PackageName         = $packageName
                Version             = $version
                ExtractExecutable   = $extractExecutable
                ExtractSilentArgs   = $extractArgs
                InstallerCommand    = $installerCommand
                InstallerSilentArgs = $installerArgs
                RebootType          = $rebootType
                PackagePath         = $PackagePath
                DescriptorPath      = $DescriptorPath
            }
            
        }
        catch {
            Write-Error "Error processing descriptor file '$DescriptorPath': $($_.Exception.Message)"
        }
    }
}