# Cronfection

This package uses a function that is made available by the installation of the `tentacles.extension` package found [here](/tentacles.extension/)

It demonstrates that you can leverage functions made available by extensions in other packages, when the extension that provides the function is installed.
You can ensure the availability of a function made available by an extension by taking on a dependency on the extension that provides it. In this example,
the `confrection` package takes a dependency on `tentacles.extension` thus ensuring the `New-ChocolateyScheduledTask` function it uses is available.
