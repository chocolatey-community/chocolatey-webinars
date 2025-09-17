# Embedded Packages

An "embedded package" is one in which the installation media required by the package is included with the package.
The most common approach is to include the necessary files in the tools folder of the package, though you may use
any folder structure you wish. Just ensure you adjust the `<files>` node of your nuspec file approapriately,
or Chocolatey will not bundle your media!

When using an embedded approach you reduce the dependencies on external systems; as long as Chocolatey can access your source
at runtime, the package will have all it needs to function correctly.

When installing from embedded media, use the [Install-ChocolateyInstallPackage](https://docs.chocolatey.org/en-us/create/functions/install-chocolateyinstallpackage/) command.
