$ErrorActionPreference = 'Stop'

$packageName = 'scripty'
$registryPath = 'HKLM:\Software\Chocolatey'
$registryKeyName = 'ScriptyDemo'

Write-Host "Creating registry key for $packageName demo..."

# Create the main Chocolatey registry path if it doesn't exist
if (-not (Test-Path $registryPath)) {
    Write-Host "Creating registry path: $registryPath"
    $null = New-Item -Path $registryPath -Force
}

# Create the demo registry key
$fullRegistryPath = Join-Path $registryPath $registryKeyName
Write-Host "Creating registry key: $fullRegistryPath"

$null = New-Item -Path $fullRegistryPath -Force

# Add some demo values to the registry key
$null = New-ItemProperty -Path $fullRegistryPath -Name "PackageName" -Value $packageName -PropertyType String -Force
$null = New-ItemProperty -Path $fullRegistryPath -Name "InstallDate" -Value (Get-Date).ToString("yyyy-MM-dd HH:mm:ss") -PropertyType String -Force
$null = New-ItemProperty -Path $fullRegistryPath -Name "Version" -Value $env:ChocolateyPackageVersion -PropertyType String -Force
$null = New-ItemProperty -Path $fullRegistryPath -Name "InstalledBy" -Value "Chocolatey" -PropertyType String -Force

Write-Host "Successfully created registry key at $fullRegistryPath with demo values"
Write-Host "Demo registry values added:"
Write-Host "  - PackageName: $packageName"
Write-Host "  - InstallDate: $((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))"
Write-Host "  - Version: $env:ChocolateyPackageVersion"
Write-Host "  - InstalledBy: Chocolatey"