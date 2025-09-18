# Elevenses / Suppertime Tasks

These packages use a function that is made available by the installation of the `toolbox.extension` package found [here](/toolbox.extension/).

They demonstrate that you can leverage functions made available by extensions in other packages, when the extension that provides the function is installed.
You can ensure the availability of a function made available by an extension by taking on a dependency on the extension that provides it. In this example,
both `elevenses-task` and `suppertime-task` take a dependency on `toolbox.extension` thus ensuring the `New-ChocolateyScheduledTask` function it uses is available.

No more storing multiple copies of the same helpers file, in source _or_ your lib directory!
