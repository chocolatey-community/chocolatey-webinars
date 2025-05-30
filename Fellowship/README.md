# Migrating your Chocolatey packages to Inedo ProGet from a Sonatype Nexus repository is straightforward. As always, there are multiple ways to migrate, depending on your exact scenario(s).

## Using the ProGet Built-In Migration tool

You can follow their [documentation](https://docs.inedo.com/docs/proget/installation/migrating-to-proget/proget-other-feed-migration) to perform the migration. This option is best when you have a single repository feed to migrate.

## Using migrator.ps1

For more complex scenarios, such as wanting to migrate multiple repositories at once, we've put together a migration tool to assist you.

### Prerequisites

To use our migration tool, you will need to install a couple of things on your Inedo ProGet server:

1. PowerShell 7+ (minimum version 7.4.6): `choco install powershell-core -y`
2. Pagootle, an Inedo ProGet management PowerShell Module : `Install-PSResource Pagootle -Repository PSGallery`
3. [A ProGet API key](https://docs.inedo.com/docs/proget/api/apikeys#creating-and-managing-api-keys): Feed Type, with all feed permissions
4. The [migrator.ps1](migrator.ps1)  script

### Set up the Migrator

1. Configure Pagootle

`Set-ProGetConfiguration -Hostname <your proget server> -ApiKey <your api key>`

>📓 NOTE 📓
> If you are using SSL with your ProGet instance, add `-UseSsl` and `-SslPort` parameters to the above command

2. Run the Migrator

`& path\to\migrator.ps1 -RepositoryUrl <your repository url>`

#### Migrator Options

`SonatypeCredential` : If your Sonatype Nexus Repository requires credentials to retrieve package information, supply a PSCredential with this parameter
`DropPath` : Provide a custom Drop path location. This folder will house the packages from Sonatype until ProGet has processed them. 
`ShowMigrationStatus` : Outputs a table with Success/Failure for each migrated package

For some advanced usage examples, run `Get-Help path\to\migrator.ps1 -Examples`

### Need Help?

Open source users can join our Discord community at [https://ch0.co/community](https://ch0.co/community) to get help performing a migration.

Commercial customers, run 'choco support' from a licensed endpoint to see your options.