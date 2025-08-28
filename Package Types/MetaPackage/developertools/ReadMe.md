# Meta packages

Chocolatey packages leverage the power already provided by the NuGet package format. This includes the ability to define package dependencies. A meta package is often just a package that will call for installation of a collection of other packages via a depedency definition with the .nuspec file.

- Use cases: Meta packages are foten used to define collections of packages such as baselines that every user in an organziation might need. They might also be department specific, such as the developertools example here is for a PowerShell and Python based development team.

Meta packages can be a great asset to reduce complexity and set good baselines.

Helpful refrences when creating Chocolatey meta packages:
- [Package Dependencies in Chocolatey](https://docs.chocolatey.org/en-us/create/package-dependencies/)
- [How to Create a Chocolatey Meta Package Guide](https://docs.chocolatey.org/en-us/guides/create/create-meta-package/)