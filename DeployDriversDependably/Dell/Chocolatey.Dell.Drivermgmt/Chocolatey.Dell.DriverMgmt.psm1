$public = Join-Path $PSScriptRoot -ChildPath 'public'
Get-ChildItem $public -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }