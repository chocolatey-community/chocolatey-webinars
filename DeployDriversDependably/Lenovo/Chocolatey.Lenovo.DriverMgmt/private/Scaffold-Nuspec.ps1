function Scaffold-Nuspec {
    <#
    .SYNOPSIS
        Creates a blank NuGet nuspec file.
    
    .DESCRIPTION
        Generates a properly formatted, empty nuspec XML file with UTF-8 encoding
        and the correct XML namespace. Used internally by package creation functions.
    
    .PARAMETER Path
        Path where the nuspec file will be created.
    
    .EXAMPLE
        Scaffold-Nuspec -Path '.\package\package.nuspec'
        
        Creates an empty nuspec file at the specified path.
    #>
    Param(
        [Parameter(Mandatory)]
        [String]
        $Path
    )

    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Indent = $true

    $utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
    $stream = [System.IO.StreamWriter]::new($Path, $false, $utf8WithoutBom)
    
    try {
        $writer = [System.Xml.XmlWriter]::Create($stream, $settings)

        $writer.WriteStartDocument()
        $writer.WriteComment("Do not remove this test for UTF-8: if 'Ω' doesn’t appear as greek uppercase omega letter enclosed in quotation marks, you should use an editor that supports UTF-8, not this one.")
        $writer.WriteStartElement('', 'package', 'http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd')
        $writer.WriteStartElement('metadata')
        $writer.WriteFullEndElement() # metadata
        $writer.WriteEndElement() # package
        $writer.WriteEndDocument()
    }
    finally {
        $writer.Flush()
        $writer.Close()
        $stream.Close()
        $stream.Dispose()
        $writer.Dispose()
    }
    return (Get-Item $Path)
}