$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$helpers = Join-Path $toolsDir -ChildPath 'helpers.ps1'
$repository = Join-Path $toolsDir -ChildPath 'Repository'
$logfile = '{0}.{1}.{2}.log' -f $env:ChocolateyPackageName,$env:ChocolateyPackageVersion,(Get-Date -Format FileDate)
$logpath = Join-path $env:TEMP -ChildPath $env:ChocolateyPackageName
$log = Join-Path $logpath -ChildPath $logfile

. $helpers

$driverMetadata = (Get-ChildItem $repository -Recurse -Filter '*.xml').FullName
$driverInfo = Get-LenovoDriverInstallInfo -DescriptorPath $drivermetadata

# Extract drivers
$extractArgs = @{
    ExeToRun = $driverInfo.ExtractExecutable
    Statements = $driverInfo.ExtractSilentArgs
    WorkingDirectory = $driverInfo.PackagePath
}

$null = Start-ChocolateyProcessAsAdmin @extractArgs

#Install the drivers
$installArgs = @{
    ExeToRun = $driverInfo.InstallerCommand
    Statements = $driverInfo.InstallerSilentArgs
    WorkingDirectory = $driverInfo.PackagePath
}

$null = Start-ChocolateyProcessAsAdmin @installArgs

Get-ChildItem $toolsDir -Recurse -Include '*.exe','*.msi' | Foreach-Object {
  $Null= New-Item "$($_.FullName).ignore" -ItemType File
}