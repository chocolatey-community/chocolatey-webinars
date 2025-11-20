function Write-Metadata {
    <#
    .SYNOPSIS
        Writes metadata to a NuGet nuspec file.
    
    .DESCRIPTION
        Updates or adds metadata elements to a Chocolatey/NuGet nuspec XML file.
        Used internally by package creation functions.
    
    .PARAMETER Metadata
        Hashtable of metadata key-value pairs to write to the nuspec.
    
    .PARAMETER NuspecFile
        Path to the nuspec file to update.
    
    .EXAMPLE
        Write-Metadata -Metadata @{title='My Package'; authors='John Doe'} -NuspecFile '.\package.nuspec'
        
        Updates the nuspec file with the specified metadata.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [Hashtable]
        $Metadata,

        [Parameter(Mandatory)]
        [String]
        $NuspecFile
    )

    process {
        [xml]$xmlDoc = Get-Content $NuspecFile

        $namespaceManager = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
        $namespaceManager.AddNamespace("ns", "http://schemas.microsoft.com/packaging/2011/08/nuspec.xsd")
        $metadataNode = $xmlDoc.SelectSingleNode("//*[local-name()='metadata']", $namespaceManager)

        $Metadata.GetEnumerator() | ForEach-Object {
            $node = $xmlDoc.SelectSingleNode("//*[local-name()='$($_.Key)']", $namespaceManager)
            if (-not $node) {
                $node = $xmlDoc.CreateElement($_.Key)
            } else {
                'Node exists: {0}, updating' -f $_.Key
            }
            $null = $node.InnerText = $_.Value
            $null = $metadataNode.AppendChild($node)
        }

        #we don't need the namespace on all the nodes, so strip it off
        $xmlDoc = $xmlDoc.OuterXml -replace 'xmlns=""', ''
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Indent = $true
        $settings.Encoding = [System.Text.Encoding]::UTF8

        $writer = [System.Xml.XmlWriter]::Create($NuspecFile, $settings)
        try {
            $xmlDoc.WriteTo($writer)
        }
        finally {
            $writer.Flush()
            $writer.Close()
            $writer.Dispose()
        }
    }
}