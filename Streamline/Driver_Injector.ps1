[CmdletBinding()]
Param()

end {
    $modelmap = @{
        '21FACTO1WW' = @{
            Network   = 'p16-nic.driver'
            Video     = 'p16-video.driver'
            Firmware  = 'p16-firmware.driver'
            Audio     = 'p16-audio.driver'
            Bluetooth = 'p16-bluetooth.driver'
        }
    }

    Write-Host 'Installing system drivers....' -ForegroundColor Green

    $systemInfo = Get-CimInstance win32_ComputerSystemProduct

    $modelmap[$systemInfo.Name].GetEnumerator() | ForEach-Object {
        Write-Host "Executing: choco install $($_.Value)" -ForegroundColor Yellow
    }

}