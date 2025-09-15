$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$helpers = Join-Path $toolsDir -ChildPath 'helpers.ps1'
. $helpers

$iso = Join-Path $toolsDir -ChildPath 'YOUR.ISO'

$packageArgs = @{
  IsoPath = $iso
  Installer = 'YOUR INSTALLER'
  SilentArgs = 'YOUR SILENT ARGS'
  ValidExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyISOPackage @packageArgs