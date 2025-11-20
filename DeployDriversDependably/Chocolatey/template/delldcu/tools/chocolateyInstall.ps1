$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repositoryPath = Join-Path $toolsDir "repository"

$processArgs = @{
    ExeToRun   = (Get-Command dcu-cli.exe).Source
    Statements = '/applyUpdates -silent -reboot=enable -repositoryLocation="{0}" -useCustomRepository' -f $repositoryPath
}

$null = Start-ChocolateyProcessAsAdmin @processArgs