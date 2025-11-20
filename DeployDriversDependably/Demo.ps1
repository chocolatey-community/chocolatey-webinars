#region Setup
Set-ExecutionPolicy Bypass -Scope Process -Force
Import-Module .\Dell\Chocolatey.Dell.Drivermgmt\Chocolatey.Dell.DriverMgmt.psd1 -Force
Import-Module .\Lenovo\Chocolatey.Lenovo.DriverMgmt\Chocolatey.Lenovo.DriverMgmt.psd1
#endregion

#region DELL DRIVERS
Clear-Host
Get-Command -Module Chocolatey.Dell.DriverMgmt

# Get a Dell Catalog
Clear-Host
Get-DellCatalog -DestinationFolder .\catalog

# Expand a catalog
Clear-Host
Expand-DellDriverFile -Catalog .\catalog\DriverPackCatalog.cab -DestinationFolder .\catalog

# Get a driver pack
Clear-Host
$packArgs = @{
    DriverCatalog  = '.\catalog\DriverPackCatalog.xml'
    DownloadFolder = '.\driverpack'
    TargetModel    = 'Latitude 5550'
    TargetOS       = 'Windows11'
}

Get-DellDriverPack @packArgs

# Get drivers from CAB

Clear-Host

$cabArgs = @{
    DownloadFolder = '.\cab'
    TargetOS       = 'Windows10', 'Windows11'
    TargetModel    = 'Latitude 5420'
    DriverCatalog  = '.\catalog\DriverPackCatalog.xml'
}

Get-DellDriverFromCAB @cabArgs

# Package for a Driver Pack stored at a url

Clear-Host

$packageArgs = @{
    PackageId       = 'dell-latitude7450win11.driver'
    DriverPack      = 'https://proget.willywonka.dev/assets/drivers/Latitude-7450-2218H_Win11_1.0_A07.exe'
    Template        = 'delldriverpack'
    OutputDirectory = 'C:\repository\dell'
    Compile         = $true
}

New-DellDriverPackage @packageArgs

# Package for a Driver Pack from local file

Clear-Host

$packageArgs = @{
    PackageId       = 'dell-memcardreaderwin10.driver'
    DriverPack      = '.\localfile\Realtek-PCIe-Memory-Card-Reader-Driver_FY1DP_WIN64_10.0.26200.21385_A01.EXE'
    Template        = 'delldriverpack'
    OutputDirectory = 'C:\repository\dell'
    Compile         = $true
}

New-DellDriverPackage @packageArgs

# Package from Dell Manifest
Clear-Host
$packageArgs = @{
    PackageId       = 'dell-latitude5420win10.driver'
    Template        = 'delldriver'
    OutputDirectory = 'C:\repository\dell'
    Category = 'audio','chipset'
    Compile         = $true
    Metadata        = '.\cab\Latitude 5420\5420-win10-A10-7PYRM\5420\Manifest.xml'
}

New-DellDriverPackage @packageArgs
#endregion


#region LENOVO DRIVERS
Get-Command -Module Chocolatey.Lenovo.DriverMgmt

# Find your machine type code
$machinecode = Get-LenovoMachineCode
$machinecode

# Get drivers by machine type code
Clear-Host
Get-AvailableLenovoDriver -MachineType $machinecode -UpdateType Driver -OperatingSystem Win11 | Format-Table

# Get drivers by model (this will include bios and firmware)
Clear-Host
Get-AvailableLenovoDriver -Model 'Thinkpad X1 Carbon' -OperatingSystem Win11 | Format-Table

# Create a driver package. This will create an audio driver package for a Thinkpad P16 Gen 2
Clear-Host
$update = Get-AvailableLenovoDriver -MachineType 21FA -UpdateType Driver -Category Audio -OperatingSystem Win11
$packageArgs = @{
    PackageId       = 'lenovo-november-audio.driver'
    UpdateData      = $update
    OutputDirectory = 'C:\lenovorepository'
    Compile         = $true
}

New-LenovoDriverPackage @packageArgs

# Create a package for all available drivers
Clear-Host
$updates = Get-AvailableLenovoDriver -MachineType 21FA -UpdateType Driver -OperatingSystem Win11 | Select-Object -First 3
foreach ($update in $updates) {
    $packageArgs = @{
        PackageId       = $update.ID
        Version         = $update.Version
        Title           = $update.Name
        OutputDirectory = 'C:\repository'
        Compile         = $true
    }

    Write-Verbose "Creating driver package for: $($update.Name)"
    New-LenovoDriverPackage @packageArgs -UpdateData $update
}

# Automating driver creation (All available drivers)
Clear-Host
$bulkArgs = @{
    MachineType = '21FA'
    #ModelList = 'Thinkpad P16 Gen 2','Thinkpad X1 Carbon'
    UpdateType = 'Driver'
    OperatingSystem = 'Win11'
    OutputDirectory = 'C:\repository'
    Category = 'audio','storage','Networking Wireless LAN'
}
. .\Lenovo\BulkCreate.ps1 @bulkArgs

# Create a metapackage for a bulk install
Clear-Host
$nupkgs = (Get-ChildItem 'C:\repository' -Filter *.nupkg).Name
$metapackageArgs = @{
    Id          = 'lenovo-webinar.drivers'
    Path        = 'C:\repository'
    Summary     = 'This is a set of drivers for the webinar'
    Description = 'Updates a few drivers as part of Unwrapping Chocolatey'
    Dependency  = $nupkgs
    Compile     = $true
}
New-LenovoMetapackage @metapackageArgs

#endregion