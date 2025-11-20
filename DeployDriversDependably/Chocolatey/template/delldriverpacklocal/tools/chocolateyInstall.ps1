$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$file = Join-Path $toolsDir -Child '[[URL]]'
$checksum = '[[CHECKSUM]]'

$packageArgs = @{
    Packagename = $env:ChocolateyPackageName
    file = $file
    checksum = $checksum
    silentArgs = '/s /i'
}

Install-ChocolateyInstallPackage @packageArgs