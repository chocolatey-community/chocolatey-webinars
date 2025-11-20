function Get-LenovoMachineCode {
    <#
.SYNOPSIS
    Retrieves the Lenovo machine type code from the current computer.

.DESCRIPTION
    This script queries the local computer's WMI/CIM information to retrieve the model name
    and extracts the first 4 characters, which represent the Lenovo machine type code.
    
    The machine type code is a 4-character identifier that Lenovo uses to uniquely identify
    different computer models. This code is essential for finding compatible drivers, BIOS
    updates, and other system-specific software from Lenovo's support resources.

.EXAMPLE
    .\Get-LenovoMachineCode.ps1
    
    Returns the 4-character machine type code for the current Lenovo computer.
    Example output: "21FA"

.EXAMPLE
    $machineType = .\Get-LenovoMachineCode.ps1
    Get-AvailableLenovoDriver -MachineType $machineType
    
    Retrieves the machine type code and uses it to find available Lenovo drivers.


.OUTPUTS
    System.String
    Returns a 4-character string representing the Lenovo machine type code.

.LINK
    Get-AvailableLenovoDriver

.LINK
    https://pcsupport.lenovo.com/
#>

    [CmdletBinding()]
    Param()

    end {
        $model = (Get-CimInstance win32_ComputerSystem).Model
        $model.Substring(0, 4)
    }
}