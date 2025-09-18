function New-ChocolateyScheduledTask {
    [CmdletBinding(DefaultParameterSetName = 'AtScript')]
    param(
        [Parameter(Mandatory)]
        [String]
        $Name,

        [Parameter(Mandatory, ParameterSetName = 'AtScript')]
        [Parameter(Mandatory, ParameterSetName = 'AtFile')]
        [string]
        $At,

        [Parameter(Mandatory, ParameterSetName = 'AtScript')]
        [Parameter(Mandatory, ParameterSetName = 'AtFile')]
        [ValidateSet('Once', 'Daily', 'Weekly')]
        $Occurance,

        [Parameter(Mandatory, ParameterSetName = 'LogonScript')]
        [Parameter(Mandatory, ParameterSetName = 'LogonFile')]
        [Switch]
        $AtLogon,

        [Parameter(Mandatory, ParameterSetName = 'StartupScript')]
        [Parameter(Mandatory, ParameterSetName = 'StartupFile')]
        [Switch]
        $AtStartup,

        [Parameter(Mandatory, ParameterSetName = 'AtScript')]
        [Parameter(Mandatory, ParameterSetName = 'LogonScript')]
        [Parameter(Mandatory, ParameterSetName = 'StartupScript')]
        [Scriptblock]
        $Script,

        [Parameter(Mandatory, ParameterSetName = 'AtFile')]
        [Parameter(Mandatory, ParameterSetName = 'LogonFile')]
        [Parameter(Mandatory, ParameterSetName = 'StartupFile')]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $File,

        [Parameter(Mandatory, ParameterSetName = 'AtScript')]
        [Parameter(Mandatory, ParameterSetName = 'LogonScript')]
        [Parameter(Mandatory, ParameterSetName = 'AtFile')]
        [Parameter(Mandatory, ParameterSetName = 'LogonFile')]
        [Parameter(Mandatory, ParameterSetName = 'StartupFile')]
        [String]
        $User,

        [Parameter(Mandatory, ParameterSetName = 'AtFile')]
        [Parameter(Mandatory, ParameterSetName = 'LogonFile')]
        [Parameter(Mandatory, ParameterSetName = 'StartupFile')]
        [String]
        $Group
    )
    end {
        $triggerParams = @{}
        $actionArgument = ''
        switch ($PSCmdlet.ParameterSetName) {
            'AtScript' {
                $date = [Datetime]::parse($At)
                $triggerParams.Add('At', $date)
                $triggerParams.Add($Occurance, $true)
                $actionArgument = '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "{0}"' -f $Script.ToString()
            }
            'AtFile' {
                $date = [Datetime]::parse($At)
                $triggerParams.Add('At', $date)
                $triggerParams.Add($Occurance, $true)
                $actionArgument = '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "& {0}"' -f $File
            }
            'LogonScript' {
                $triggerParams.Add('AtLogon', $true)
                $actionArgument = '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "{0}"' -f $Script.ToString()
            }
            'LogonFile' {
                $triggerParams.Add('AtLogon', $true)
                $actionArgument = '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "& {0}"' -f $File
            }
            'StartupScript' {
                $triggerParams.Add('AtStartup', $true)
                $actionArgument = '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "{0}"' -f $Script.ToString()
            }
            'StartupFile' {
                $triggerParams.Add('AtStartup', $true)
                $actionArgument = '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -Command "& {0}"' -f $File
            }
        }
        $action = New-ScheduledTaskAction -Execute powershell.exe -Argument $actionArgument
        $trigger = New-ScheduledTaskTrigger @triggerParams
        $settings = New-ScheduledTaskSettingsSet

        $principal = if ($User) {
            New-ScheduledTaskPrincipal -UserId $User
        } elseif ($Group) {
            New-ScheduledTaskPrincipal -GroupId $Group
        }

        $task = New-ScheduledTask -Action $action -Principal $principal -Trigger $trigger -Settings $settings
        Register-ScheduledTask $Name -InputObject $task
    }
}