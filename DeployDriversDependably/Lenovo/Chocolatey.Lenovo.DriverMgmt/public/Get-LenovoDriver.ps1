function Get-LenovoDriver {
    <#
    .SYNOPSIS
        Downloads Lenovo drivers and creates Chocolatey packages in bulk.
    
    .DESCRIPTION
        Queries the Lenovo update catalog for available drivers and automatically creates
        Chocolatey packages for each driver found. Supports filtering by machine type, model,
        update type, category, severity, and operating system. This is a convenience function
        that combines Get-AvailableLenovoDriver with New-LenovoDriverPackage for bulk operations.
    
    .PARAMETER ModelList
        Array of Lenovo model names to download drivers for (e.g., 'ThinkPad X1 Carbon', 'ThinkPad P16 Gen 2').
        Use this parameter to look up machine types by model name.
    
    .PARAMETER MachineType
        Array of Lenovo machine type codes to download drivers for (e.g., '21FA', '20QN').
        Machine type codes are 4-character identifiers for specific Lenovo models.
    
    .PARAMETER UpdateType
        Filter by update type. Valid values: 'Application', 'Driver', 'Bios', 'Firmware'.
        If not specified, returns all update types.
    
    .PARAMETER RebootType
        Filter by reboot requirements. Valid values:
        - 'Forced reboot': Update initiates the reboot
        - 'Requires reboot': Installer initiates the reboot
        - 'Forces shutdown': Update initiates shutdown
        - 'Delayed forced reboot': Used for firmware with countdown timer
    
    .PARAMETER Severity
        Filter by update severity. Valid values: 'Critical', 'Recommended', 'Other'.
    
    .PARAMETER OperatingSystem
        Target operating system. Valid values: 'Win10', 'Win11'. Defaults to 'Win11'.
    
    .PARAMETER Category
        Filter drivers by category. This parameter is only available when UpdateType is 'Driver'.
        Valid values include: 'Audio', 'Storage', 'Display and Video Graphics', 'Networking Wireless LAN',
        'Camera and Card Reader', 'Bluetooth and Modem', and more.
    
    .PARAMETER OutputDirectory
        Directory where Chocolatey packages will be created. Defaults to current directory.
    
    .EXAMPLE
        Get-LenovoDriver -MachineType '21FA' -UpdateType Driver -OperatingSystem Win11 -OutputDirectory C:\packages
        
        Downloads all drivers for machine type 21FA (ThinkPad P16 Gen 2) and creates Chocolatey packages.
    
    .EXAMPLE
        Get-LenovoDriver -ModelList 'ThinkPad X1 Carbon' -UpdateType Driver -Category 'Audio','Networking Wireless LAN' -OutputDirectory C:\packages
        
        Downloads only audio and wireless LAN drivers for ThinkPad X1 Carbon models.
    
    .EXAMPLE
        Get-LenovoDriver -MachineType '21FA','20QN' -UpdateType Driver -Severity Critical -OutputDirectory C:\packages
        
        Downloads critical driver updates for multiple machine types.
    
    .NOTES
        This function automatically compiles packages to .nupkg files. All created packages
        will be ready for deployment to a Chocolatey repository.
    #>
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
        [String]
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
}