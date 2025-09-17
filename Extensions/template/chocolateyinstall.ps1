$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$exe = Join-Path $toolsDir -ChildPath "nyan.exe"
$script = [scriptblock]::Create("& `"$exe`" --lifespan=10s")

$Scripttask = @{
  Name      = 'Task - {0} ({1})' -f $env:ChocolateyPackageName, 'Scriptblock'
  At        = (Get-Date).AddSeconds(20).ToString()
  Occurance = 'Daily'
  User      = $env:USERNAME
  Script    = $script
}

# Define a sriptblock for the task to run 20 seconds from now, daily.
New-ChocolateyScheduledTask @Scripttask
