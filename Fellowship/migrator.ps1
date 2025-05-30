#Requires -Modules Pagootle

<#
.SYNOPSIS
Migrates Chocolatey packages from one or more Sonatype Nexus repositories to a Inedo ProGet feed.

.DESCRIPTION
This script automates the migration of Chocolatey packages from specified repositories to ProGet feeds. It retrieves package metadata, downloads the packages, and uploads them to ProGet feeds. If the specified ProGet feed does not exist, the script creates it. Additionally, it sets up a drop folder for the feed to optimize package import performance.

.PARAMETER RepositoryUrl
Specifies one or more URLs of the repositories to migrate packages from. This parameter is mandatory.

.PARAMETER SonatypeCredential
Specifies the credentials to use when accessing the source repositories. This parameter is optional and should be a PSCredential object.

.PARAMETER DropPath
Specifies the local directory where the downloaded packages will be temporarily stored before being imported into ProGet. Defaults to 'C:\drop'

.PARAMETER ShowMigrationStatus
If specified, the script will return a summary of the migration process, including the status of each package.

.EXAMPLE
.\migrator.ps1 -RepositoryUrl "https://example.com/repository/choco-repo/" -DropPath "C:\Temp\Packages"

Migrates all packages from the specified repository to ProGet, using the specified drop path for temporary storage.

.EXAMPLE
.\migrator.ps1 -RepositoryUrl "https://example.com/repository/choco-repo/" -SonatypeCredential (Get-Credential) -ShowMigrationStatus

.EXAMPLE
.\migrator.ps1 -RepositoryUrl "https://example.com/repository/repoA/","https://example.com/repository/repoB/" -SonatypeCredential (Get-Credential) -ShowMigrationStatus

Migrates all packages from the specified repositories to ProGet, using the provided credentials for authentication and displaying a summary of the migration process.

.NOTES
- The script requires the `Pagootle` module to be installed.
- ProGet feeds are created automatically if they do not already exist.
- The script uses ProGet's drop folder feature to optimize package import performance.
- Ensure that the `DropPath` directory has sufficient space and write permissions.

#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String[]]
    $RepositoryUrl,

    [Parameter()]
    [PSCredential]
    [Alias('RepositoryCredential','Credential')]
    $SonatypeCredential,

    [Parameter()]
    [String]
    $DropPath = 'C:\drop',

    [Parameter()]
    [Switch]
    $ShowMigrationStatus
)

begin {
    function Get-StatusCode {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory)]
            [String]
            $Url,

            [Parameter()]
            [PSCredential]
            $Credential
        )

        $request = [System.Net.WebRequest]::Create($Url)

        if ($Credential) {
            $request.Credentials = $Credential
        }

        $response = $request.GetResponse()
        $response.StatusCode
    }
}

process {
    # set up collections to hold data as we migrate
    $allPackages = [System.Collections.Generic.List[PSCustomobject]]::New()
    $migration = [System.Collections.Generic.List[pscustomobject]]::new()

    # process packages from each repo
    $RepositoryUrl | Foreach-Object {

        $currentRepo = $_
        
        # Determine the name of the repository based on url
        $matcher = 'https?:\/\/[^\/]+\/repository\/(?<RepositoryName>[^\/]+)\/'
        $null = $currentRepo -match $matcher

        # Set the drop path where nupkgs will be downloaded too
        $RepoDropPath = Join-Path $DropPath -ChildPath $matches.RepositoryName

        # Get all the packages out of the current repository, and add them to our collection of packages to process later
        $chocoArgs = @('search', "--source='$currentRepo'", '--all-versions', '--pre', '--limit-output')

        # If we need credentials, add them to our args
        if ($SonatypeCredential) {
            $chocoArgs += @("--user='$($SonatypeCredential.UserName)'", "--password='$($SonatypeCredential.GetNetworkCredential().Password)'")
        }
        
        # We need to make a sensible object, so add some properties
        $propertyBag = @(@{Name = 'PackageId' ; Expression = { $_.P } }
            @{Name = 'PackageVersion'; Expression = { $_.V } }
            @{Name = 'Repository' ; Expression = { $currentRepo } }
            @{Name = 'DropPath' ; Expression = { $RepoDropPath } }
        )

        $null = & choco @chocoArgs | ConvertFrom-Csv -Delimiter '|' -Header P, V | Select-Object -Property $propertyBag | ForEach-Object { $allPackages.Add($_) }
        
        # Create feeds in ProGet if they don't exist already
        Write-Host "Checking for ProGet Feed: $($matches.RepositoryName)"
        try {
            $null = Get-ProGetFeed -Feed $matches.RepositoryName -ErrorAction Stop
            Write-Host 'Feed exists!'
        }

        catch {
            Write-Host 'Feed was not found. Creating...'
            $null = New-ProGetFeed -Name $matches.RepositoryName -Type chocolatey -Active
        }

        # Setup a drop folder for the feed. ProGet will import any packages into a feed from its Drop Folder, and clean up the nupkg when complete. Free performance!
        New-ProGetFeedDropPath -Feed $matches.RepositoryName -DropPath $RepoDropPath

        # Now we process all the packages from our repositories into their new homes
        $allPackages | Foreach-Object {
            Write-Verbose "Migrating $($_.PackageId) with version $($_.PackageVersion)"

            # Determine Repository feed
            $matcher = 'https?:\/\/[^\/]+\/repository\/(?<RepositoryName>[^\/]+)\/'
            $null = $_.Repository -match $matcher


            # Determine package url
            $PackageUrl = "$($_.Repository -replace '/index\.json$')/v3/content/{0}/{1}/{0}.{1}.nupkg" -f $_.PackageId, $_.PackageVersion
            Write-Verbose "Testing $PackageUrl"
         
            # Test the url
            if (-not $SonatypeCredential) {
                $code = Get-StatusCode -Url $PackageUrl
            }
            else {
                $code = Get-StatusCode -Url $PackageUrl -Credential $SonatypeCredential
            }
    
            $downloader = [System.Net.WebClient]::New()
        
            if ($SonatypeCredential) {
                $downloader.Credentials = $SonatypeCredential
            }

            # Save the nupkg if we can
            if ($Code -eq 'OK') {
                $file = Join-Path $_.DropPath -ChildPath (Split-Path -Leaf $PackageUrl)
            
                try {
                    $downloader.DownloadFile($PackageUrl, $file)
                    $success = 'Success'
                }
                catch {
                    $success = 'Failed'
                }

                $migrationObject = [PSCustomObject]@{
                    Status         = $success
                    PackageId      = $_.PackageId
                    PackageVersion = $_.PackageVersion
                    Nupkg          = $file
                }

                $migration.Add($migrationObject)
            }

            # Otherwise log the failure
            else {
                $err = 'Download location for {0} with version {1} is unavailable. Package will not be migrated.' -f $_.PackageId, $_.PackageVersion
                Write-Error $err
            
                $migrationObject = [PSCustomObject]@{
                    Status         = 'Failed'
                    PackageId      = $_.PackageId
                    PackageVersion = $_.PackageVersion
                    Nupkg          = $null
                }

                $migration.Add($migrationObject)

            }        
        } #end package loop
    
        # Inform folks that ProGet needs to process the migration before use
        Write-Warning "Waiting until ProGet finishes processing $RepoDropPath"
        do {
            Write-Host "." -NoNewline
            Start-Sleep -Seconds 2
        } while ((Get-ChildItem -Path $RepoDropPath).Count -gt 0)

        Write-Host "Finished Processing repository: $($matches.RepositoryName)!"
    }


}

end {
    # Provide migration summary if requested
    if ($ShowMigrationStatus) {
        return $migration
    }
}