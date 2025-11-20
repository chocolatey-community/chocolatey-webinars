<#
.SYNOPSIS
    Installs a custom Chocolatey package template to the Chocolatey templates directory.

.DESCRIPTION
    This script copies a custom Chocolatey package template from a specified folder
    to the Chocolatey templates directory, making it available for use with the
    'choco new' command. The script:
    
    1. Checks if the Chocolatey templates directory exists
    2. Creates the templates directory if it doesn't exist
    3. Copies all files from the template folder to the Chocolatey templates directory
    
    Once installed, the template can be used to generate new packages with
    'choco new <package-name> --template=<template-name>'.

.PARAMETER TemplateFolder
    The path to the folder containing the custom template files.
    Defaults to a 'template' subfolder in the current directory.
    
.EXAMPLE
    .\Install-Template.ps1
    
    Installs the template from the default 'template' folder in the current directory
    to the Chocolatey templates directory.

.EXAMPLE
    .\Install-Template.ps1 -TemplateFolder 'C:\CustomTemplates\lenovo'
    
    Installs a custom template from the specified folder path.

.EXAMPLE
    .\Install-Template.ps1 -TemplateFolder '.\my-custom-template' -Verbose
    
    Installs the template from a relative path with verbose output showing
    detailed progress information.

.EXAMPLE
    Get-ChildItem C:\Templates -Directory | ForEach-Object { .\Install-Template.ps1 -TemplateFolder $_.FullName }
    
    Installs multiple templates by iterating through subdirectories.
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [String]
    $TemplateFolder = (Join-path $PSScriptRoot -ChildPath 'template')
)

process {
    $chocolateyTemplate = if (-not (Test-Path $env:ChocolateyInstall\templates)) {
        New-Item $env:ChocolateyInstall\templates -ItemType Directory   
    }
    else {
        "$env:ChocolateyInstall\templates"
    }

    Copy-Item $TemplateFolder\* -Destination $chocolateyTemplate -Recurse
}