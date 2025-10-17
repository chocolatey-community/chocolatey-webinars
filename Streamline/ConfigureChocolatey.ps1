[CmdletBinding()]
Param(
    [Parameter()]
    [Hashtable]$AdditionalConfiguration,

    # Allows for the toggling of additional features that is applied after the base configuration.
    # Can override base configuration with this parameter.
    # We expect to pass in feature information as a hashtable in the following format:
    # @{
    #     useBackgroundservice = 'Enabled'
    # }
    [Parameter()]
    [Hashtable]$AdditionalFeatures,

    # Allows for the installation of additional packages after the system base packages have been installed.
    # We expect to pass in one or more hashtables with package information in the following format:
    # @{
    #     Id = 'firefox'
    #     # Optional:
    #     Version = 123.4.56
    #     Pin = $true
    # }
    [Parameter()]
    [Hashtable[]]$AdditionalPackages,

    # Allows for the addition of alternative sources after the base conifguration  has been applied.
    # Can override base configuration with this parameter
    # We expect to pass in one or more hashtables with source information in the following format:
    # @{
    #     Name = 'MySource'
    #     Source = 'https://nexus.fabrikam.com/repository/MyChocolateySource'
    #     # Optional:
    #     Credentials = $MySourceCredential
    #     AllowSelfService = $true
    #     AdminOnly = $true
    #     BypassProxy = $true
    #     Priority = 10
    #     Certificate = 'C:\cert.pfx'
    #     CertificatePassword = 's0mepa$$'
    # }
    [Parameter()]
    [Hashtable[]]$AdditionalSources
)

end {

    if ($AdditionalConfiguration) {
        $AdditionalConfiguration.GetEnumerator().ForEach{
            & choco @(
                'config'
                'set'
                "--name='$($_.Key)'"
                "--value='$($_.Value)'"
                '--limit-output'
            )
        }
    }

    if ($AdditionalFeatures) {
        $AdditionalFeatures.GetEnumerator().ForEach{
            $State = switch ($_.Value) {
                ($_ -in @('true', 'enable', 'enabled') -or ($_ -is [bool] -and $_ -eq $true)) { 'enable' }
                ($_ -in @($false, 'false', 'disable', 'disabled')) { 'disable' }
                default { Write-Error "State of '$($_.Key)' should be either Enabled or Disabled" }
            }
            if ($State) {
                & choco @(
                    'feature'
                    $State
                    "--name='$($_.Key)'"
                    '--limit-output'
                )
            }
        }
    }

    if ($AdditionalSources) {
        foreach ($Source in $AdditionalSources) {
            & choco @(
                'source'
                'add'
                "--name='$($Source.Name)'"
                "--source='$($Source.Source)'"
                if ($Source.ContainsKey('Credentials')) {
                    "--user='$($Source.Credentials.Username)'"
                    "--password='$($Source.Credentials.GetNetworkCredential().Password)'"
                }
                if ($Source.AllowSelfService) { '--allow-self-service' }
                if ($Source.AdminOnly) { '--admin-only' }
                if ($Source.BypassProxy) { '--bypass-proxy' }
                if ($Source.Priority) { "--priority='$($Source.Priority)'" }
                if ($Source.Certificate) { "--cert='$($Source.Certificate)'" }
                if ($Source.CerfificatePassword) { "--certpassword='$($Source.CertificatePassword)'" }
                '--limit-output'
            )
        }
    }

    if ($AdditionalPackages) {
        foreach ($Package in $AdditionalPackages) {
            & choco @(
                'install'
                $Package.Id
                if ($Package.Version) { "--version='$($Package.Version)'" }
                if ($Package.Pin) { '--pin' }
                '--confirm'
                '--no-progress'
                '--limit-output'
            )
        }
    }
}