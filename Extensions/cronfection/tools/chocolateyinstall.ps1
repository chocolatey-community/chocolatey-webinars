$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$taskScript = Join-Path $toolsDir -ChildPath ('{0}_task.ps1' -f $env:ChocolateyPackageName)

$Scripttask = @{
  Name      = 'Task - {0} ({1})' -f $env:ChocolateyPackageName, 'Scriptblock'
  At        = '8pm'
  Occurance = 'Daily'
  User      = $env:USERNAME
  Script    = { Write-Host 'Hello World!' }
}

# Define a sriptblock for the task to run at 8pm, daily.
New-ChocolateyScheduledTask @Scripttask

$Filetask = @{
  Name      = 'Task - {0} ({1})' -f $env:ChocolateyPackageName, 'Scriptblock'
  AtStartup        = $true
  User      = $env:USERNAME
  File    = $taskScript
}

# Define a file for the task to run at startup
New-ChocolateyScheduledTask @Filetask