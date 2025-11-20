function New-DriverPack {
    <#
    .SYNOPSIS
        Creates an XML configuration file containing package information.
    
    .DESCRIPTION
        This script generates an XML file with a structure similar to packages.config,
        containing package entries with customizable attributes. Each package must have an 'id'
        attribute and can include additional attributes such as version, source, or any other
        metadata. The script uses XmlWriter for efficient XML generation with proper UTF-8 encoding.
    
    .PARAMETER Path
        The file path where the XML configuration file will be created. If the file already exists,
        it will be overwritten. The path should include the filename and .config or .xml extension.
    
    .PARAMETER DriverPackage
        An array of hashtables where each hashtable represents a package. Each hashtable must
        contain at least an 'id' key. Additional keys will be added as XML attributes to the package
        element. Common attributes include:
        - id (required): Unique identifier for the package
        - version: Version number of the package
        - source: Custom package source location
        - installArguments: Arguments to pass during installation
        - packageParameters: Package-specific parameters
        - forceX86: Force x86 installation on x64 systems
        - ignoreDependencies: Ignore package dependencies
        - executionTimeout: Timeout in seconds for package installation
        - force: Force package installation
    
    .EXAMPLE
        .\New-DriverPack.ps1 -Path .\packages.config -DriverPackage @{id = 'apackage'}
        
        Creates a packages.config file with a single package entry containing only the id attribute.
        Output: <package id="apackage" />
    
    .EXAMPLE
        .\New-DriverPack.ps1 -Path .\packages.config -DriverPackage @{id = 'anotherPackage'; version = '1.1'}
        
        Creates a package entry with an id and version attribute.
        Output: <package id="anotherPackage" version="1.1" />
    
    .EXAMPLE
        .\New-DriverPack.ps1 -Path .\packages.config -DriverPackage @{id = 'chocolateytestpackage'; version = '0.1'; source = 'somelocation'}
        
        Creates a package entry with id, version, and a custom source location.
        Output: <package id="chocolateytestpackage" version="0.1" source="somelocation" />
    
    .EXAMPLE
        $package = @{
            id = 'alloptions'
            version = '0.1.1'
            source = 'https://somewhere/api/v2/'
            installArguments = ''
            packageParameters = ''
            forceX86 = 'false'
            ignoreDependencies = 'false'
            executionTimeout = '1000'
            force = 'false'
        }
        .\New-DriverPack.ps1 -Path .\packages.config -DriverPackage $package
        
        Creates a package entry with all available options specified.
    
    .EXAMPLE
        $packages = @(
            @{id = 'apackage'},
            @{id = 'anotherPackage'; version = '1.1'},
            @{id = 'chocolateytestpackage'; version = '0.1'; source = 'somelocation'}
        )
        .\New-DriverPack.ps1 -Path .\packages.config -DriverPackage $packages
        
        Creates multiple package entries with varying attributes in a single configuration file.
    
    .OUTPUTS
        System.IO.FileInfo
        Returns a FileInfo object for the created XML configuration file.
    
    .NOTES
        The generated XML structure matches the packages.config format:
        <?xml version="1.0" encoding="utf-8"?>
        <packages>
          <package id="driver-name" version="1.0.0" />
          <package id="another-driver" />
        </packages>
        
        The script uses UTF-8 encoding without BOM for maximum compatibility.
        All packages are written during the process block, allowing pipeline support.
    
    .LINK
    https://docs.chocolatey.org/en-us/choco/commands/install/#packagesconfig
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Path,

        [Parameter(Mandatory)]
        [Hashtable[]]
        $DriverPackage
    )

    begin {
        $settings = [System.Xml.XmlWriterSettings]::new()
        $settings.Indent = $true
        $settings.Encoding = [System.Text.UTF8Encoding]::new($false)

        $writer = [System.Xml.XmlWriter]::Create($Path, $settings)
    
        try {

            $writer.WriteStartDocument()
            $writer.WriteStartElement('packages')
        }
        catch {
            $writer.Dispose()
            throw
        }
    }


    process {
        foreach ($Package in $DriverPackage) {
            $writer.WriteStartElement('package')
            $writer.WriteAttributeString('id', $Package['id'])
            
            # Add any additional attributes from the hashtable
            $Package.GetEnumerator() | Where-Object { $_.Key -ne 'id' } | ForEach-Object {
                $writer.WriteAttributeString($_.Key, $_.Value)
            }
            
            $writer.WriteEndElement() # package
        }
    }

    end {
        try {
            $writer.WriteEndElement() # packages
            $writer.WriteEndDocument()
        }
        finally {
            $writer.Flush()
            $writer.Close()
            $writer.Dispose()
        }
        return (Get-Item $Path)
    }
}