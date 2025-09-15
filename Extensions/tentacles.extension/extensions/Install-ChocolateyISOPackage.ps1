function Install-ChocolateyISOPackage {
    [CmdletBinding(DefaultParameterSetName = 'default')]
    Param(
        [Parameter(ParameterSetName = 'embedded')]
        [Parameter(ParameterSetName = 'remote')]
        [ValidateScript({ Test-Path $_ })]
        [String]
        $IsoPath = $toolsDir,

        [Parameter(Mandatory, ParameterSetName = 'remote')]
        [String]
        $IsoUrl,

        [Parameter(Mandatory)]
        [String]
        $Installer,

        [Parameter(Mandatory)]
        [String]
        $SilentArgs,

        [Parameter()]
        [Int[]]
        $ValidExitCodes = @(0, 3010, 1641)
    )

    end {
        switch ($PSCmdlet.ParameterSetName) {
            'embedded' {
                $isoDrive = Mount-DiskImage -ImagePath $IsoPath | Get-Volume
                $driveLetter = (Resolve-Path ('{0}:' -f $isoDrive.DriveLetter)).Path
                $file = Join-Path $driveLetter -ChildPath $Installer
            }

            'remote' {
                $Iso = Split-Path -Lear $IsoUrl
                $IsoFile = Join-Path $IsoPath -ChildPath $Iso

                [System.Net.WebClient]::new().DownloadFile($IsoUrl, $IsoFile)

                $isoDrive = Mount-DiskImage -ImagePath $isoFIle | Get-Volume
                $driveLetter = (Resolve-Path ('{0}:' -f $isoDrive.DriveLetter)).Path
                $file = Join-Path $driveLetter -ChildPath $Installer
            }
        }

        $packageArgs = @{
            PackageName    = $env:ChocolateyPackageName
            FileType       = $file.Split('.')[-1]
            File           = $file
            SilentArgs     = $SilentArgs
            ValidExitCodes = $ValidExitCodes
        }

        Install-ChocolateyInstallPackage @packageArgs
    }
}