$ErrorActionPreference = 'Stop' # stop on all errors
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"


$fileLocation = Join-Path $toolsDir -ChildPath 'vlc-3.0.21-win32.exe' 
$fileLocation64 = Join-Path $toolsDir -ChildPath 'vlc-3.0.21-win64.exe' 

$packageArgs = @{
  packageName    = $env:ChocolateyPackageName
  unzipLocation  = $toolsDir
  fileType       = 'EXE' #only one of these: exe, msi, msu
  file           = $fileLocation
  file64         = $fileLocation64
  softwareName   = 'VLC media*' 
  checksum       = '4BD03202B6633F9611B3FC8757880A9B2B38C7C0C40ED6BCBEFEC71C0099D493'
  checksumType   = 'sha256'
  checksum64     = '9742689A50E96DDC04D80CEFF046B28DA2BEEFD617BE18166F8C5E715EC60C59'
  checksum64Type = 'sha256'
  silentArgs     = '/S'
  validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyInstallPackage @packageArgs # https://docs.chocolatey.org/en-us/create/functions/install-chocolateyinstallpackage
