$TaskName = 'Task - {0} (Scriptblock)' -f $env:ChocolateyPackageName

Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false