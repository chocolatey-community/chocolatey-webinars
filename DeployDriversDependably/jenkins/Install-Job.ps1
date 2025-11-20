<#
.SYNOPSIS
    Installs a Jenkins job from an XML configuration file.

.DESCRIPTION
    The Install-Job script deploys a Jenkins job by copying its XML configuration file 
    to the appropriate directory in the Jenkins home folder. The script validates that 
    Jenkins is running, creates the necessary job folder structure, and restarts Jenkins 
    to register the new job.

.PARAMETER JenkinsHome
    The path to the Jenkins home directory where job configurations are stored.
    Defaults to 'C:\ProgramData\Jenkins\.jenkins'.
    The path must exist.

.PARAMETER Name
    The name of the Jenkins job to create. This will be used as the folder name 
    under the Jenkins jobs directory.
    Defaults to 'Build Driver Package'.

.PARAMETER JobFile
    The path to the XML configuration file for the Jenkins job. The file must:
    - Exist on the filesystem
    - Have an .xml extension
    This parameter is mandatory.

.EXAMPLE
    .\Install-Job.ps1 -JobFile C:\configs\MyJob.xml

    Installs a Jenkins job named 'Build Driver Package' using the specified XML configuration file.

.EXAMPLE
    .\Install-Job.ps1 -Name 'Deploy Application' -JobFile C:\configs\deploy.xml

    Creates a Jenkins job named 'Deploy Application' using the provided configuration.

.EXAMPLE
    .\Install-Job.ps1 -JenkinsHome 'D:\Jenkins' -Name 'Test Job' -JobFile C:\configs\test.xml

    Installs a job in a custom Jenkins home directory.

.NOTES
    Requires:
    - Jenkins service must be installed and running
    - Administrative privileges to restart the Jenkins service
    - Write access to the Jenkins home directory

    The script will:
    1. Validate Jenkins service exists
    2. Create the job folder if it doesn't exist
    3. Copy the XML configuration file
    4. Restart Jenkins service to register the new job
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [ValidateScript({ Test-Path $_ })]
    [String]
    $JenkinsHome = 'C:\ProgramData\Jenkins\.jenkins',

    [Parameter()]
    [String]
    $Name = 'Build Driver Package',

    [Parameter()]
    [ValidateScript({
            if (-not (Test-Path $_)) {
                throw "File '$_' does not exist."
            }
            if ((Get-Item $_).Extension -ne '.xml') {
                throw "File '$_' must be an XML file."
            }
            return $true
        })]
    [String]
    $JobFile,

    [Parameter()]
    [Switch]
    $NoRestartService
)

begin {
    if (-not (Get-Service jenkins -ErrorAction SilentlyContinue)) {
        throw 'Jenkins is required to run this script and is not found'
    }
}

end {
    $jobRoot = Join-Path $JenkinsHome -ChildPath 'jobs'
    $jobFolder = Join-Path $jobRoot -ChildPath $Name

    if (-not (Test-Path $jobFolder)) {
        Write-Verbose 'Creating job folder'
        $null = New-Item $jobFolder -i Directory
    }

    Write-Verbose 'Copying job config to folder'
    Copy-Item $JobFile -Destination $jobFolder
    Write-Verbose 'Job installed'
    
    if (-not $NoRestartService) {
        Write-Verbose 'Restarting Jenkins to pickup newly added job'
        Restart-Service jenkins
    }
    else {
        Write-Warning 'User passed -NoRestartService. New job will be unavailable until service restarts.'
    }

}