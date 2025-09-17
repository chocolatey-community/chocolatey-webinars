$ErrorActionPreference = 'Stop' # stop on all errors
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"

$url = 'https://www.7-zip.org/a/7z2501.msi'
$url64 = 'https://www.7-zip.org/a/7z2501-x64.msi'

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  fileType       = 'msi' #only one of these: exe, msi, msu
  url           = $url
  url64         = $url64
  softwareName   = '7-zip*' 
  checksum       = 'DCE9E456ACE76B969FE0FE4D228BF096662C11D2376D99A9210F6364428A94C4'
  checksumType   = 'sha256'
  checksum64     = 'E7EB0B7ED5EFA4E087B7B17F191797F7AF5B7F442D1290C66F3A21777005EF57'
  checksum64Type = 'sha256'
  silentArgs     = "/quiet /norestart /l*v `"$($env:TEMP)\$($env:chocolateyPackageName).$($env:chocolateyPackageVersion).MsiInstall.log`""
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs # https://docs.chocolatey.org/en-us/create/functions/install-chocolateypackage
