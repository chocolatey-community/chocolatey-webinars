$ErrorActionPreference = 'Stop'

$ScriptTask = @{
  Name      = "Task - $($env:ChocolateyPackageName) (ScriptBlock)"
  At        = '11am'
  Occurance = 'Daily'
  User      = $env:USERNAME
  Script    = { Write-Host 'Time for a snack!' }
}

# Define a scriptblock for the task to run at elevenses, daily.
New-ChocolateyScheduledTask @ScriptTask