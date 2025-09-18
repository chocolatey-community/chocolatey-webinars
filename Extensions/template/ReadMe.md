# Template

A tutorial on how to create a chocolatey template with a dependency on an extension and build a package with from that template.

## Intent
- Create a reusable Chocolatey template that references the extension.
- Generate a package from the template using the function `New-ChocolateyScheduledTask` exposed from the extension.
- Test install and uninstall of the resulting package.

## References
- [Chocolatey Template Tutorial](https://docs.chocolatey.org/en-us/guides/create/create-template/)
- [Chocolatey Configuration](https://docs.chocolatey.org/en-us/configuration/#general)
- [Nyan](https://github.com/michaelgov-ctrl/nyan)
