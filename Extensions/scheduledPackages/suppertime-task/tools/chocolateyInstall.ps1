$ErrorActionPreference = 'Stop'
$toolsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

$ScriptTask = @{
  Name      = "Task - $($env:ChocolateyPackageName) (ScriptBlock)"
  At        = '8pm'
  Occurance = 'Daily'
  User      = $env:USERNAME
  Script    = { Write-Host 'Stop working! Have dinner!' }
}

# Define a scriptblock for the task to run at 8pm, daily.
New-ChocolateyScheduledTask @ScriptTask

$FileTask = @{
  Name      = "Task - $($env:ChocolateyPackageName) (File)"
  AtStartup = $true
  User      = $env:USERNAME
  File      = Join-Path $toolsDir "logon-task.ps1"
}

# Define a file for the task to run at startup
New-ChocolateyScheduledTask @FileTask