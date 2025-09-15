Get-ChildItem $PSScriptRoot -Filter *.ps1 -Recurse | Foreach-Object { . $_.Fullname }

Export-ModuleMember -Function Install-ChocolateyISOPackage, New-ChocolateyScheduledTask