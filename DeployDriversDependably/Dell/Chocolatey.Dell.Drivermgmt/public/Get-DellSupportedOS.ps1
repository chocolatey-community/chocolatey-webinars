function Get-DellSupportedOS {
    <#
    .SYNOPSIS
        Extracts and identifies all supported Operating Systems from a Dell Driver Pack Catalog CAB file.
    
    .DESCRIPTION
        This function extracts the DriverPackCatalog.xml from the specified CAB file and parses it to 
        retrieve a unique list of all supported Operating Systems across all driver packages in the catalog.
    
    .PARAMETER CatalogPath
        The path to the DriverPackCatalog.cab file. If not specified, uses the Dell subfolder in the current directory.
    
    .PARAMETER DownloadLatest
        Switch parameter. If specified, downloads the latest catalog from Dell's website instead of using a local file.
    
    .PARAMETER GroupByModel
        Switch parameter. If specified, groups the operating systems by model/brand.
    
    .PARAMETER ExportToCSV
        Optional path to export the results to a CSV file.
    
    .EXAMPLE
        Get-DellSupportedOS
        Lists all supported Operating Systems from the default catalog location.
    
    .EXAMPLE
        Get-DellSupportedOS -CatalogPath "C:\Temp\DriverPackCatalog.cab"
        Lists all supported Operating Systems from the specified CAB file.
    
    .EXAMPLE
        Get-DellSupportedOS -DownloadLatest
        Downloads the latest catalog and lists all supported Operating Systems.
    
    .EXAMPLE
        Get-DellSupportedOS -GroupByModel
        Lists supported Operating Systems grouped by computer model.
    
    .EXAMPLE
        Get-DellSupportedOS -ExportToCSV "C:\Reports\SupportedOS.csv"
        Exports the list of supported Operating Systems to a CSV file.
    
    .OUTPUTS
        PSCustomObject with OperatingSystem property, or grouped results if -GroupByModel is specified.
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$CatalogPath = "$PSScriptRoot\Dell\DriverPackCatalog.cab",
        
        [Parameter(Mandatory = $false)]
        [switch]$DownloadLatest,
        
        [Parameter(Mandatory = $false)]
        [switch]$GroupByModel,
        
        [Parameter(Mandatory = $false)]
        [string]$ExportToCSV
    )
    
    begin {
        Write-Verbose "Starting Get-DellSupportedOS function"
        
        # Create temporary directory for extraction
        $TempFolder = Join-Path -Path $env:TEMP -ChildPath "DellCatalog_$(Get-Date -Format 'yyyyMMddHHmmss')"
        if (!(Test-Path $TempFolder)) {
            New-Item -Path $TempFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Created temporary folder: $TempFolder"
        }
        
        # Handle download of latest catalog
        if ($DownloadLatest) {
            Write-Verbose "Downloading latest catalog from Dell..."
            $CatalogURL = "http://downloads.dell.com/catalog/DriverPackCatalog.cab"
            $CatalogPath = Join-Path -Path $TempFolder -ChildPath "DriverPackCatalog.cab"
            
            try {
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($CatalogURL, $CatalogPath)
                Write-Verbose "Download complete: $CatalogPath"
            }
            catch {
                Write-Error "Failed to download catalog: $($_.Exception.Message)"
                return
            }
        }
        
        # Verify CAB file exists
        if (!(Test-Path -Path $CatalogPath)) {
            Write-Error "Catalog file not found: $CatalogPath"
            return
        }
        
        Write-Verbose "Using catalog file: $CatalogPath"
    }
    
    process {
        try {
            # Extract XML from CAB file
            $XMLFilePath = Join-Path -Path $TempFolder -ChildPath "DriverPackCatalog.xml"
            Write-Verbose "Extracting XML from CAB file to: $XMLFilePath"
            
            # Use expand.exe to extract the XML
            $expandOutput = & expand.exe $CatalogPath $XMLFilePath 2>&1
            
            if (!(Test-Path -Path $XMLFilePath)) {
                Write-Error "Failed to extract XML from CAB file"
                Write-Verbose "Expand output: $expandOutput"
                return
            }
            
            # Load and parse XML
            Write-Verbose "Loading XML catalog..."
            [xml]$Catalog = Get-Content -Path $XMLFilePath
            
            # Get catalog version
            $CatalogVersion = $Catalog.DriverPackManifest.version
            Write-Host "Catalog Version: $CatalogVersion" -ForegroundColor Cyan
            
            # Extract all driver packages
            $DriverPackages = $Catalog.DriverPackManifest.DriverPackage
            Write-Host "Total Driver Packages: $($DriverPackages.Count)" -ForegroundColor Cyan
            
            if ($GroupByModel) {
                # Group by Model with OS information
                Write-Verbose "Processing driver packages with model grouping..."
                $ModelOSData = @()
                
                foreach ($DriverPackage in $DriverPackages) {
                    # Get model information
                    $Brand = if ($DriverPackage.SupportedSystems.Brand.Display.'#cdata-section') {
                        $DriverPackage.SupportedSystems.Brand.Display.'#cdata-section'.Trim()
                    } else { "N/A" }
                    
                    $Model = if ($DriverPackage.SupportedSystems.Brand.Model.Display.'#cdata-section') {
                        $DriverPackage.SupportedSystems.Brand.Model.Display.'#cdata-section'.Trim()
                    } else { "N/A" }
                    
                    $FullModel = "$Brand $Model".Trim()
                    
                    # Get supported operating systems
                    if ($DriverPackage.SupportedOperatingSystems.OperatingSystem) {
                        foreach ($OS in $DriverPackage.SupportedOperatingSystems.OperatingSystem) {
                            $OSName = $OS.Display.'#cdata-section'.Trim()
                            
                            $ModelOSData += [PSCustomObject]@{
                                Brand            = $Brand
                                Model            = $Model
                                FullModel        = $FullModel
                                OperatingSystem  = $OSName
                                DriverPackage    = $DriverPackage.Name.Display.'#cdata-section'.Trim()
                            }
                        }
                    }
                }
                
                # Display grouped results
                Write-Host "`nSupported Operating Systems by Model:" -ForegroundColor Green
                Write-Host ("=" * 80) -ForegroundColor Green
                
                $GroupedData = $ModelOSData | Group-Object -Property FullModel | Sort-Object Name
                
                foreach ($Group in $GroupedData) {
                    Write-Host "`n$($Group.Name)" -ForegroundColor Yellow
                    $UniqueOS = $Group.Group | Select-Object -ExpandProperty OperatingSystem -Unique | Sort-Object
                    foreach ($OS in $UniqueOS) {
                        Write-Host "  - $OS" -ForegroundColor White
                    }
                }
                
                # Return the data
                if ($ExportToCSV) {
                    $ModelOSData | Export-Csv -Path $ExportToCSV -NoTypeInformation -Force
                    Write-Host "`nData exported to: $ExportToCSV" -ForegroundColor Green
                }
                
                return $ModelOSData
                
            } else {
                # Extract unique OS list
                Write-Verbose "Extracting unique Operating Systems..."
                $AllOperatingSystems = @()
                
                foreach ($DriverPackage in $DriverPackages) {
                    if ($DriverPackage.SupportedOperatingSystems.OperatingSystem) {
                        foreach ($OS in $DriverPackage.SupportedOperatingSystems.OperatingSystem) {
                            $OSName = $OS.Display.'#cdata-section'.Trim()
                            $AllOperatingSystems += $OSName
                        }
                    }
                }
                
                # Get unique OS list and sort
                $UniqueOS = $AllOperatingSystems | Select-Object -Unique | Sort-Object
                
                # Display results
                Write-Host "`nSupported Operating Systems ($($UniqueOS.Count) unique):" -ForegroundColor Green
                Write-Host ("=" * 80) -ForegroundColor Green
                
                $Results = @()
                $Counter = 1
                foreach ($OS in $UniqueOS) {
                    Write-Host "$Counter. $OS" -ForegroundColor White
                    $Results += [PSCustomObject]@{
                        Number = $Counter
                        OperatingSystem = $OS
                    }
                    $Counter++
                }
                
                # Export to CSV if requested
                if ($ExportToCSV) {
                    $Results | Export-Csv -Path $ExportToCSV -NoTypeInformation -Force
                    Write-Host "`nData exported to: $ExportToCSV" -ForegroundColor Green
                }
                
                return $Results
            }
            
        }
        catch {
            Write-Error "Error processing catalog: $($_.Exception.Message)"
            Write-Verbose "Stack Trace: $($_.ScriptStackTrace)"
        }
    }
    
    end {
        # Cleanup temporary files
        if (Test-Path $TempFolder) {
            Write-Verbose "Cleaning up temporary files..."
            Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Verbose "Get-DellSupportedOS function completed"
    }
}

# Example usage (uncomment to run):
# Get-DellSupportedOS -Verbose
# Get-DellSupportedOS -GroupByModel
# Get-DellSupportedOS -DownloadLatest -ExportToCSV "C:\Reports\DellOS.csv"
