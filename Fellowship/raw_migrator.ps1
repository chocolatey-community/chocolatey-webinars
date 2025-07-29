#requires -Modules NexuShell
#requires -Modules Pagootle
<#
.SYNOPSIS
    Migrates raw assets from a Nexus repository to ProGet.

.DESCRIPTION
    This script downloads raw assets from a specified Nexus repository and uploads them to a corresponding ProGet asset feed.
    If the ProGet feed doesn't exist, it will be created automatically. The script supports filtering assets and handles
    existing assets gracefully by providing appropriate warnings.

.PARAMETER NexusRepository
    The name of the Nexus repository from which to migrate assets. This parameter is mandatory.

.PARAMETER NexusCredential
    Optional PSCredential object containing the username and password for authenticating with the Nexus repository.
    If not provided, the script will attempt to connect anonymously.

.PARAMETER Filter
    Optional ScriptBlock to filter which assets should be migrated. The filter is applied to the asset objects
    returned from Get-NexusAsset. For example: { $_.name -like "*.zip" }

.EXAMPLE
    .\raw_migrator.ps1 -NexusRepository "my-raw-repo"

    Migrates all assets from the "my-raw-repo" Nexus repository to a ProGet feed with the same name.

.EXAMPLE
    $cred = Get-Credential
    .\raw_migrator.ps1 -NexusRepository "my-raw-repo" -NexusCredential $cred

    Migrates all assets from the "my-raw-repo" Nexus repository using the provided credentials.

.EXAMPLE
    .\raw_migrator.ps1 -NexusRepository "my-raw-repo" -Filter { $_.name -like "*.zip" }

    Migrates only ZIP files from the "my-raw-repo" Nexus repository.

.EXAMPLE
    .\raw_migrator.ps1 -NexusRepository "my-raw-repo" -Filter { $_.lastModified -gt (Get-Date).AddDays(-30) }

    Migrates only assets that were modified within the last 30 days.

.NOTES
    Prerequisite: This script requires the NexuShell and Pagootle PowerShell modules to be installed and imported.
    They must have run Get-ProGetConfiguration

    The script creates a temporary directory for downloading assets and cleans up automatically.
    Existing assets in ProGet will not be overwritten; a warning will be displayed instead.
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [String]
    $NexusRepository,

    [Parameter()]
    [PSCredential]
    $NexusCredential,

    [Parameter()]
    [Scriptblock]
    $Filter = {$true}  # Defaulting this to "everything" so we can streamline the logic later
)
begin {
    $tempDir = New-Item (Join-Path $env:TEMP -ChildPath (New-Guid).Guid) -ItemType Directory
    $downloader = [System.Net.Webclient]::New()

    if ($NexusCredential) {
        $downloader.Credentials = $NexusCredential
    }

    if (-not (Get-ProGetConfiguration)) {
        # We need the user to have run the Pagootle configuration
        Set-ProGetConfiguration  # I have no idea if this will mandatory-default the right values - probably not. Maybe just throw?
    }

    if (-not (Get-ProGetFeed -Feed $NexusRepository -ErrorAction SilentlyContinue)) {
        Write-Verbose -Message $('Creating missing ProGet asset feed: {0}' -f $NexusRepository)
        $ProGetRepository = New-ProGetFeed -Name $NexusRepository -Type asset -Active
    }

    $assets = Get-NexusAsset -RepositoryName $NexusRepository | Where-Object $Filter

    Write-Verbose "Found $($assets.Count) assets to migrate"

    foreach ($asset in $assets) {
        # Get the file from Nexus
        $Name = Split-Path -Leaf $asset.downloadurl
        $File = Join-Path $tempDir -ChildPath $Name
        $downloader.DownloadFile($($asset.downloadurl), $File)

        # Upload to ProGet
        $progetArgs = @{
            Path           = $File
            AssetDirectory = $ProGetRepository.Name
            Folder         = Split-Path -Parent $asset.Path
        }

        try {
            New-ProGetAsset @progetArgs -ErrorAction Stop
        }
        catch {
            if ($_.Exception.Message -eq 'The specified asset already exists. Run with -Force to overwrite!'){
                Write-Warning 'The specified asset already exists.'
            }
            else {
                throw # meant to rethrow instead of just outputting the exception?
            }
        } finally {
            Remove-Item $File  # Remove each file as we go, so we don't fill up a disk accidentally.
        }
    }
}
end {
    Remove-Item $tempDir -Recurse -Force
}