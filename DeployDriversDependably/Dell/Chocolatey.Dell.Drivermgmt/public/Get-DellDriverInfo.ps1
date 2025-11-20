function Get-DellDriverInfo {
    <#
    .SYNOPSIS
        Retrieves driver information from Dell catalog for a specific model.
    
    .DESCRIPTION
        Queries the Dell driver catalog XML file to find driver packages for a specified model
        and optionally filters by operating system.
    
    .PARAMETER Model
        The Dell model name to search for (e.g., 'Latitude 5420').
    
    .PARAMETER OperatingSystem
        Optional operating system filter. Valid values: 'Windows 11', 'Windows 10', 'winPE10x', 'winpe11x'.
    
    .PARAMETER CatalogXml
        Path to the Dell DriverPackCatalog.xml file.
    
    .EXAMPLE
        Get-DellDriverInfo -Model 'Latitude 5420' -CatalogXml '.\catalog\DriverPackCatalog.xml'
        
        Gets all driver packages for Latitude 5420.
    
    .EXAMPLE
        Get-DellDriverInfo -Model 'Latitude 5550' -OperatingSystem 'Windows 11' -CatalogXml '.\catalog\DriverPackCatalog.xml'
        
        Gets Windows 11 driver packages for Latitude 5550.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [String]
        $Model,

        [Parameter()]
        [ValidateSet('Windows 11', 'Windows 10', 'winPE10x', 'winpe11x')]
        [String]
        $OperatingSystem,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $CatalogXml
    )

    end {
        [xml]$catalog = Get-Content $CatalogXml
        $packages = $catalog.DriverPackManifest.DriverPackage
        $filter = if ($OperatingSystem) {
            { 
                ($_.SupportedSystems.Brand.Model.name -eq $Model) -and 
                ($_.SupportedOperatingSystems.OperatingSystem.Display.'#cdata-section' -match $OperatingSystem)
            }
        }
        else {
            { ($_.SupportedSystems.Brand.Model.name -eq $Model) }
        }

        $packages | Where-Object $filter
    }
}