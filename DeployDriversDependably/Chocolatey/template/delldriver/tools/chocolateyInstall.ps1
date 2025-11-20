$ErrorActionPreference = 'Stop'
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$repositoryPath = Join-Path $toolsDir "repository"

Write-Host "Installing Dell drivers from repository..."

# Find all .inf files in the repository
$infFiles = Get-ChildItem -Path $repositoryPath -Filter "*.inf" -Recurse -File

if ($infFiles.Count -eq 0) {
    throw "No drivers found in package!"
}

# Install each driver using pnputil
foreach ($inf in $infFiles) {   
    try {
        $processArgs = @{
            ExeToRun = (Get-Command pnputil.exe).Source
            Statements = '/add-driver "{0}" /install' -f $inf.FullName
        }
        $null = Start-ChocolateyProcessAsAdmin @processArgs
    }
    catch {
        throw "Failed to install: $($_.Exception.Message)"
    }
}

    Write-Host "Drivers installed successfully. A system reboot may be required for changes to take effect."

Get-ChildItem $repositoryPath -Filter *.exe -Recurse | ForEach-Object {
    $null = New-Item "$($_.FullName).ignore" -ItemType File
}