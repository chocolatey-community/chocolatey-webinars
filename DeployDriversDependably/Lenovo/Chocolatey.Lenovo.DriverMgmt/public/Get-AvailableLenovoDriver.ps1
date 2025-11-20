
function Get-AvailableLenovoDriver {
    <#
    .SYNOPSIS
        Retrieves available Lenovo drivers, BIOS updates, firmware, and applications for a specific machine type.
    
    .DESCRIPTION
        The Get-AvailableLenovoDriver function queries the Lenovo update catalog to find available updates 
        for a specified machine type. It provides filtering capabilities based on update type, reboot 
        requirements, severity level, and operating system version. This function is a wrapper around 
        the Find-LnvUpdate cmdlet with user-friendly parameter mappings.
    
    .PARAMETER MachineType
        The Lenovo machine type identifier (e.g., '21FA', '20QN'). This is a 4-character code that 
        identifies the specific Lenovo model. This parameter is mandatory.
    
    .PARAMETER UpdateType
        Filters results by the type of update. Valid values are:
        - Application: Software applications and utilities
        - Driver: Hardware drivers
        - Bios: BIOS/UEFI firmware updates
        - Firmware: Other firmware updates
        If not specified, returns all update types.
    
    .PARAMETER RebootType
        Filters results by Reboot requirements. Valid values are:
        - 'Forced reboot': Update itself initiates the reboot
        - 'Requires reboot': Thin Installer/System Update/CV initiates the reboot
        - 'Forces shutdown': Update itself initiates shutdown
        - 'Delayed forced reboot': Used for firmware, Thin Installer/System Update/CV will enforce reboot with dialog displaying count-down timer
        If not specified, returns updates with any reboot requirement.
    
    .PARAMETER Severity
        Filters results by update severity level. Valid values are:
        - Critical: Critical security or stability updates
        - Recommended: Important but non-critical updates
        - Other: Optional updates
        If not specified, returns updates of all severity levels.
    
    .PARAMETER OperatingSystem
        Filters results by Windows operating system version. Valid values are:
        - Win10: Windows 10
        - Win11: Windows 11
        If not specified, returns updates for all supported operating systems.
    
    .PARAMETER Category
        Filters driver results by category. This parameter is only available when UpdateType is set to 'Driver'.
        Valid values include:
        - Software and Utilities
        - Docking Station and Port Replicator
        - Storage
        - Camera and Card Reader
        - Mouse Pen and Keyboard
        - Motherboard Devices Backplanes core chipset onboard video PCIe switches
        - Networking Wireless WAN
        - Fingerprint reader
        - USB Device FireWire IEEE 1394 Thunderbolt
        - Display and Video Graphics
        - Audio
        - Networking Wireless LAN
        - Power Management
        - Bluetooth and Modem
        If not specified, returns drivers from all categories.
    
    .EXAMPLE
        Get-AvailableLenovoDriver -MachineType 21FA
        
        Retrieves all available updates for machine type 21FA.
    
    .EXAMPLE
        Get-AvailableLenovoDriver -MachineType 21FA -UpdateType Application
        
        Retrieves only application updates for machine type 21FA.
    
    .EXAMPLE
        Get-AvailableLenovoDriver -MachineType 20QN -UpdateType Driver -OperatingSystem Win11
        
        Retrieves all driver updates for machine type 20QN that are compatible with Windows 11.
    
    .EXAMPLE
        Get-AvailableLenovoDriver -MachineType 21FA -UpdateType Driver -Category 'Networking Wireless LAN'
        
        Retrieves only Wireless LAN driver updates for machine type 21FA.
    
    .EXAMPLE
        Get-AvailableLenovoDriver -MachineType 21FA -Severity Critical -RebootType 'Requires reboot'
        
        Retrieves all critical updates for machine type 21FA that require a system reboot.
    
    .EXAMPLE
        Get-AvailableLenovoDriver -MachineType 21FA -UpdateType Bios -OperatingSystem Win10
        
        Retrieves BIOS updates for machine type 21FA that are compatible with Windows 10.
    
    .OUTPUTS
        Returns update objects from Find-LnvUpdate containing details about available updates including:
        - Package ID
        - Title
        - Version
        - Download URL
        - Release date
        - File size
        - And other update metadata
    
    .NOTES
        This function requires the Lenovo update module that provides the Find-LnvUpdate cmdlet.
        Machine type codes can typically be found on the Lenovo product label or in system information.
    
    .LINK
        Find-LnvUpdate
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'MachineType')]
        [String[]]
        $MachineType,

        [Parameter(Mandatory, ParameterSetName = 'Model')]
        [String[]]
        $Model,

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
        $OperatingSystem = 'Win11'
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
        $typeMap = @{
            Application = 1
            Driver      = 2
            Bios        = 3
            Firmware    = 4
        }

        $rebootMap = @{
            'Forced reboot'         = 1
            'Requires reboot'       = 3
            'Forces shutdown'       = 4
            'Delayed forced reboot' = 5
        }

        $severityMap = @{
            Critical    = 1
            Recommended = 2
            Other       = 3
        }

        $osMap = @{
            Win10 = 10
            Win11 = 11
        }

        $updates = [System.Collections.Generic.List[PSObject]]::new()
    }

    end {

        switch ($PSCmdlet.ParameterSetName) {
            'MachineType' {
                foreach ($item in $MachineType) {
                    $searchArgs = @{MachineType = $item }

                    if ($UpdateType) {
                        $searchArgs.Add('PackageType', $typeMap[$UpdateType])
                    }
                    if ($RebootType) {
                        $searchArgs.Add('RebootType', $rebootMap[$RebootType])
                    }
                    if ($Severity) {
                        $searchArgs.Add('Severity', $severityMap[$Severity])
                    }
                    if ($OperatingSystem) {
                        $searchArgs.Add('WindowsVersion', $osMap[$OperatingSystem])
                    }

                    $updatedata = Find-LnvUpdate @searchArgs -ListAll
                    
                    $filteredData = if ($PSBoundParameters.ContainsKey('Category')) {
                        $updatedata | Where-Object Category -in $PSBoundParameters['Category']
                    }
                    else {
                        $updatedata
                    }

                    foreach ($update in $filteredData) {
                        $updates.Add($update)
                    }
                    
                }
            }

            'Model' {
                foreach ($item in $Model) {
                    $machineTypeString = Find-LnvMachineType -ModelName "$item"
                    # Retrieve only machine codes from returned string
                    $MachineTypeCode = $machineTypeString.Split('=')[-1].Split(' ').Trim().Where{ $_ }[0]

                    $searchArgs = @{MachineType = $MachineTypeCode }

      
                    if ($UpdateType) {
                        $searchArgs.Add('PackageType', $typeMap[$UpdateType])
                    }
                    if ($RebootType) {
                        $searchArgs.Add('RebootType', $rebootMap[$RebootType])
                    }
                    if ($Severity) {
                        $searchArgs.Add('Severity', $severityMap[$Severity])
                    }
                    if ($OperatingSystem) {
                        $searchArgs.Add('WindowsVersion', $osMap[$OperatingSystem])
                    }

                    $updatedata = Find-LnvUpdate @searchArgs -ListAll
                    
                    $filteredData = if ($PSBoundParameters.ContainsKey('Category')) {
                        $updatedata | Where-Object Category -in $PSBoundParameters['Category']
                    }
                    else {
                        $updatedata
                    }

                    foreach ($update in $filteredData) {
                        $updates.Add($update)
                    }
                   
                }
            }
        }
  
        return $updates
    }
}