function Expand-DellDriverFile {
    <#
    .SYNOPSIS
        Extracts Dell driver pack or catalog files.
    
    .DESCRIPTION
        Expands Dell driver pack executables or CAB files to a specified destination folder.
        Supports both self-extracting driver pack EXE files and Dell catalog CAB files.
    
    .PARAMETER DellDriverPack
        Path to a Dell driver pack EXE file to extract.
    
    .PARAMETER Catalog
        Path to a Dell catalog CAB file to extract.
    
    .PARAMETER DestinationFolder
        The folder where files will be extracted. Defaults to the current directory.
    
    .EXAMPLE
        Expand-DellDriverFile -Catalog .\DriverPackCatalog.cab -DestinationFolder .\catalog
        
        Extracts the Dell catalog CAB file to the catalog folder.
    
    .EXAMPLE
        Expand-DellDriverFile -DellDriverPack .\Latitude-5420_Win10_A10.exe -DestinationFolder .\drivers
        
        Extracts a Dell driver pack to the drivers folder.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, ParameterSetName = 'Pack')]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $DellDriverPack,

        [Parameter(Mandatory, ParameterSetName = 'Cab')]
        [ValidateScript({ 
            if (-not (Test-Path $_)) {
                throw "File '$_' does not exist."
            }
            if ([System.IO.Path]::GetExtension($_) -ne '.cab') {
                throw "File '$_' is not a .cab file."
            }
            $true
        })]
        [String]
        $Catalog,

        [Parameter()]
        [String]
        $DestinationFolder = $PWD
    )

    end {
        
        switch ($PSCmdlet.ParameterSetName) {
            'Pack' {
                $process = @{
                    FilePath     = $DellDriverPack
                    ArgumentList = '/s', "/e=$DestinationFolder"
                    Wait         = $true
                }

                Start-Process @process
            }

            'Cab' {
                $xmlFile = (Split-Path $Catalog -Leaf) -replace '.cab','.xml'
                $xmlPath = Join-Path $DestinationFolder -ChildPath $xmlFile
                $null = & expand.exe "$Catalog" /F:* "$xmlPath"
                Get-Item $xmlPath
            }
        }
        
    }
}