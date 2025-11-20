$public = Join-Path $PSScriptRoot -ChildPath 'public'
$private = Join-Path $PSScriptRoot -ChildPath 'private'
Get-ChildItem $public,$private -Recurse -Filter *.ps1 | ForEach-Object { . $_.FullName }