<# 
Required when autouninstaller is not available or otherwise disabled.
Also used to reverse an action performed via either chocolateyInstall.ps1
operation, such as unsetting a registry key that was set when the package
was installed.
#>

$ErrorActionPreference = 'Stop'

$packageName = 'scripty'
$registryPath = 'HKLM:\Software\Chocolatey'
$registryKeyName = 'ScriptyDemo'
$fullRegistryPath = Join-Path $registryPath $registryKeyName

Write-Host "Removing registry key for $packageName..."

# Check if the registry key exists before attempting to remove it
if (Test-Path $fullRegistryPath) {
    Write-Host "Removing registry key: $fullRegistryPath"
    $null = Remove-Item -Path $fullRegistryPath -Recurse -Force
    Write-Host "Successfully removed registry key: $fullRegistryPath"
} else {
    Write-Host "Registry key not found: $fullRegistryPath (may have been already removed)"
}

# Optionally clean up the parent Chocolatey registry key if it's empty
# Only remove if there are no other subkeys
$parentKey = Get-Item -Path $registryPath -ErrorAction SilentlyContinue
if ($parentKey -and ($parentKey.SubKeyCount -eq 0) -and ($parentKey.ValueCount -eq 0)) {
    Write-Host "Parent Chocolatey registry key is empty, removing: $registryPath"
    $null = Remove-Item -Path $registryPath -Force
}