function Get-DellCatalog {
    <#
    .SYNOPSIS
        Downloads the Dell driver catalog CAB file.
    
    .DESCRIPTION
        Downloads the latest Dell DriverPackCatalog.cab file from Dell's download servers
        or from a custom URL if specified.
    
    .PARAMETER CatalogUrl
        URL to the Dell driver catalog CAB file. Defaults to Dell's official catalog URL.
    
    .PARAMETER DestinationFolder
        Folder where the catalog will be saved. Defaults to the current directory.
    
    .EXAMPLE
        Get-DellCatalog -DestinationFolder .\catalog
        
        Downloads the Dell catalog to the catalog folder.
    
    .EXAMPLE
        Get-DellCatalog -CatalogUrl 'https://custom.url/catalog.cab' -DestinationFolder C:\Temp
        
        Downloads a catalog from a custom URL.
    #>
    [CmdletBinding()]
    Param(
        [Parameter()]
        [String]
        $CatalogUrl = 'https://downloads.dell.com/catalog/DriverPackCatalog.cab',

        [Parameter()]
        [String]
        $DestinationFolder = $PWD

    )

    begin {
        if (-not (Test-Path $DestinationFolder)) {
            $Null = New-item $DestinationFolder -ItemType Directory
        }
    }
    end {
        Write-Verbose 'Downloading latest catalog from Dell...'
        $CatalogPath = Join-Path -Path $DestinationFolder -ChildPath 'DriverPackCatalog.cab'
            
        try {
           Invoke-WebRequest -Uri $CatalogUrl -OutFile $CatalogPath
            Write-Verbose "Download complete: $CatalogPath"
        }
        catch {
            Write-Error "Failed to download catalog: $($_.Exception.Message)"
            return
        }

        Get-Item $CatalogPath
    }
}