# Remote installers

Like the Chocolatey Community Repository, you can host your installers externally to the package,
and have the installers consumed at runtime. You can use this approach to pull installers from web servers,
raw/generic repository feeds, or even fileshares (though fileshares are the _least_ recommended approach).

To execute a remote installer in a Chocolatey package use the [Install-ChocolateyPackage](https://docs.chocolatey.org/en-us/create/functions/install-chocolateypackage/) helper function!

This remote installer approach is recommended when the installation media is greater than 2GB in size. If working with install
media below the 2GB mark, it is advised to use an embedded package.
