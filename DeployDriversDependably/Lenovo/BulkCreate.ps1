
[CmdletBinding()]
Param(
    [Parameter(Mandatory, ParameterSetName = 'Model')]
    [String[]]
    $ModelList,

    [Parameter(Mandatory, ParameterSetName = 'MachineType')]
    [String[]]
    $MachineType,

    [Parameter()]
    [ValidateSet('Application', 'Driver', 'Bios', 'Firmware')]
    [String[]]
    $UpdateType,

    [Parameter()]
    [ValidateSet('Forced reboot', 'Requires reboot', 'Forces shutdown', 'Delayed forced reboot')]
    [String]
    $RebootType,

    [Parameter()]
    [ValidateSet('Critical', 'Recommended', 'Other')]
    [string]
    $Severity,

    [Parameter()]
    [ValidateSet('Win10', 'Win11')]
    [String]
    $OperatingSystem = 'Win11',

    [Parameter()]
    [String]
    $OutputDirectory = $PWD

)

DynamicParam {
    # Only add Category parameter if UpdateType is Driver
    if ($PSBoundParameters['UpdateType'] -eq 'Driver') {
        $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        
        # Define the Category parameter
        $categoryAttribute = New-Object System.Management.Automation.ParameterAttribute
        $categoryAttribute.Mandatory = $false
        $categoryAttribute.HelpMessage = "Filter drivers by category"
        
        $attributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $attributeCollection.Add($categoryAttribute)
        
        # Add ValidateSet for Lenovo driver categories
        $validateSet = New-Object System.Management.Automation.ValidateSetAttribute(
            'Software and Utilities',
            'Docking Station and Port Replicator',
            'Storage',
            'Camera and Card Reader',
            'Mouse Pen and Keyboard',
            'Motherboard Devices Backplanes core chipset onboard video PCIe switches',
            'Networking Wireless WAN',
            'Fingerprint reader',
            'USB Device FireWire IEEE 1394 Thunderbolt',
            'Display and Video Graphics',
            'Audio',
            'Networking Wireless LAN',
            'Power Management',
            'Bluetooth and Modem'
        )
        $attributeCollection.Add($validateSet)
        
        $categoryParam = New-Object System.Management.Automation.RuntimeDefinedParameter(
            'Category', [string[]], $attributeCollection
        )
        
        $paramDictionary.Add('Category', $categoryParam)
        
        return $paramDictionary
    }
}
    
begin {
    # Clean up what we'll pass to Get-AvailableLenovoDriver later
    $commandArgs = $PSBoundParameters
    $null = $commandArgs.Remove('ModelList')
    $null = $commandArgs.Remove('MachineType')
    $null = $commandArgs.Remove('OutputDirectory')
    
    # Handle dynamic Category parameter
    if ($PSBoundParameters.ContainsKey('Category')) {
        $commandArgs['Category'] = $PSBoundParameters['Category']
    }
}

process {

    $drivers = switch ($PSCmdlet.ParameterSetName) {
        
        'Model' {
            # Loop over all our models
            foreach ($model in $ModelList) {
                # Get the machine codes
                Write-Verbose "Looking up type code for $model"
                $machineTypeString = Find-LnvMachineType -ModelName $Model
                # Retrieve only first machine code from returned string
                $machineCode = $machineTypeString.Split('=')[-1].Split(' ').Trim().Where{ $_ }[0]
                Write-Verbose "Getting drivers for $machineCode"
                Get-AvailableLenovoDriver -MachineType $machineCode @commandArgs
            }
        }

        'MachineType' {
            foreach ($item in $MachineType) {
                Get-AvailableLenovoDriver -MachineType $item @commandArgs
            }
        }
    }

    foreach ($driver in $drivers) {
        $packageArgs = @{
            PackageId       = $driver.ID
            Version         = $driver.Version
            Title           = $driver.Name
            OutputDirectory = $OutputDirectory
            Compile         = $true
        }

        Write-Verbose "Creating driver package for: $($driver.Name)"
        New-LenovoDriverPackage @packageArgs -UpdateData $driver
    }
}
