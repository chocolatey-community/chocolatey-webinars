$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$url = '[[URL]]'
$checksum = '[[CHECKSUM]]'

$packageArgs = @{
    Packagename = $env:ChocolateyPackageName
    Url = $url
    checksum = $checksum
    silentArgs = '/s /i'
}

Install-ChocolateyPackage @packageArgs