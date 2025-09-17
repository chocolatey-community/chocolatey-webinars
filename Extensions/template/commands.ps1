
# init extension
choco pack ..\toolbox.extension\toolbox.extension.nuspec
choco install toolbox.extension --source="'.'" -y

# setup template: https://docs.chocolatey.org/en-us/guides/create/create-template/
$templateName = "InstallTemplateWithExtensions"

# create items for new template
# templates are stored in `C:\ProgramData\chocolatey\templates`
$templateDir = "C:\ProgramData\chocolatey\templates\$TemplateName"

New-Item -Path $templateDir, "$templateDir\tools" -ItemType Directory

# create templated .nuspec
# packageNameLower & PackageVersion are `automatic` variables
@'
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>[[PackageNameLower]]</id>
    <version>[[PackageVersion]]</version>
    <owners>SweetTooth</owners>
    <title>[[PackageName]] [[PackageVersion]] (Install)</title>
    <authors>Chocolatey</authors>
    <tags>[[Tags]]</tags>
    <summary>Install [[PackageName]]</summary>
    <description>Install [[PackageName]]</description>
    <dependencies>
        <dependency id="tentacles.extension" version="1.0.0" />
    </dependencies>
  </metadata>
  <files>
    <file src="tools\**" target="tools" />
  </files>
</package>
'@ | Set-Content "$templateDir\file.nuspec"


# set as default template
# https://docs.chocolatey.org/en-us/configuration/#general
choco config set --name="'defaultTemplateName'" --value="'$templateName'"


# generate a new package from the template, setup install, and pack it
$packageName = 'nyan'
$packageVersion = '1.0.42'
$tags = 'nyan install scheduled'
choco new $packageName --version="$packageVersion" Tags=$tags

Copy-Item .\nyan.exe .\nyan\tools
Copy-Item .\chocolateyinstall.ps1 .\nyan\tools
Copy-Item .\chocolateyuninstall.ps1 .\nyan\tools

choco pack .\$packageName\$packageName.nuspec


# test install and uninstall
choco install $packageName --source="'.'" -y

choco uninstall $packageName -y