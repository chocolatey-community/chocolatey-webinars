# Vanilla - A Bad Practices Demonstration

Vanilla, while an _excellent_ choice in ice cream, is an example of a bad practice when authoring Chocolatey packages.
The term "bad" is subjective here, as a Chocolatey package authored in the way the `vanilla` package is authored is perfectly valid.
There is just a "better way", that being using extensions.

## Why is this a "Bad" example?

The `vanilla` package uses a helper function that has been defined inside of a `helpers.ps1` file contained within the package itself.
This helper function is only available to the `vanilla` package. To use it other places you would need to recreate the file in each package that needs it. This can be problematic as you need to:

- Maintain the file
- Remember where it is
- Remember to include it in your package.
- Remember to dot source it in any scripts that need it.

Extensions allow you to write it once, and use it anywhere the extension is installed without any further special handling required. Much less effort!

## How would you make it better?

Instead of having a helpers file, why not add a dependency on the [chocolatey-isomount.extension](https://community.chocolatey.org/packages/chocolatey-isomount.extension) package by Maurice Kevenaar, which is used in a multitude of other packages!