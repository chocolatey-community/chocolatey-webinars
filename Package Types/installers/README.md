# Installers

When you are attempting to install software via a package you need one of two things:

- To embed the installer in the package by placing it in the tools folder
- To point to the download location for the installer

If embedding the installer in the package, use the `Install-ChocolateyInstallPackage` function

If fetching the installer from a remote resource at runtime, use the `Install-ChocolateyPackage` function