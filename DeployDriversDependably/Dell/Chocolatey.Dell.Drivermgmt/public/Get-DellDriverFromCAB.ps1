function Get-DellDriverFromCAB {

	#========================================================================
	# Created by:   Dustin Hedges
	# Filename:     Download-DellDriverPacks.ps1
	# Version: 		1.0.0.1
	# Comment: 		This script will download the latest available Dell Driver
	# 				Catalog file from the web, search for any matching OS or
	# 				Model strings and download the appropriate Dell Driver
	# 				CAB Files to the specified Download Folder.
	#========================================================================
	<#
.Synopsis
   Downloads the latest available Driver CAB files from Dell
.DESCRIPTION
   Downloads the latest Dell Driver Catalog file (unless a local copy is supplied) and downloads any new Driver CAB's listed in that catalog.
.EXAMPLE
   .\Download-DellDriverPacks.ps1 -DownloadFolder "E:\Dell\Drivers\DellCatalog" -TargetModel "Latitude E7240" -Verbose

.EXAMPLE
   .\Download-DellDriverPacks.ps1 -DownloadFolder "E:\Dell\Drivers\DellCatalog" -TargetOS 64-bit_-_WinPE_5.0 -Verbose

.EXAMPLE
   .\Download-DellDriverPacks.ps1 -DownloadFolder "E:\Dell\Drivers\DellCatalog" -TargetModel "Latitude E7440" -TargetOS Windows_8.1_64-bit -Verbose
#>
	[CmdletBinding()]
	Param
	(
		[Parameter(Mandatory = $false,
			ValueFromPipelineByPropertyName = $true,
			Position = 0,
			HelpMessage = "DriverPackCatalog.cab file.  By default will download from http://downloads.dell.com")]
		[string]$DriverCatalog = "http://downloads.dell.com/catalog/DriverPackCatalog.cab",
	
		[Parameter(Mandatory = $true,
			ValueFromPipelineByPropertyName = $true,
			Position = 1)]
		[string]$DownloadFolder,
	
		[Parameter(Mandatory = $false,
			ValueFromPipelineByPropertyName = $true,
			Position = 2,
			HelpMessage = "The Model of System you wish to download files for.  Example: Latitude E7240.")]
		[string]$TargetModel = "WinPE",
	
	[Parameter(Mandatory = $false,
		ValueFromPipelineByPropertyName = $true,
		Position = 3,
		HelpMessage = "The Operating System(s) you wish to download files for.")]
	[ValidateSet("Vista", "XP", "Windows7", "Windows8", "Windows8.1", "Windows10", "Windows11", "winpe3x", "winpe4x", "winpe5x", "winpe10x", "winpe11x")]
	[string[]]$TargetOS
)	Begin {
	
		# Trim Trailing '\' from DownloadFolder if it exists
		if ($DownloadFolder.Substring($DownloadFolder.Length - 1, 1) -eq "\") {
			$DownloadFolder = $DownloadFolder.Substring(0, $DownloadFolder.Length - 1)
		}
	
	
		# Create DownloadFolder if it does not exist
		if (!(Test-Path $DownloadFolder)) {
			Try {
				New-Item -Path $DownloadFolder -ItemType Directory -Force | Out-Null
			}
			Catch {
				Write-Error "$($_.Exception)"
			}
		}
	
	
		# Download Latest Catalog and Extract
		if ($DriverCatalog -match "ftp" -or $DriverCatalog -match "http") {
		
			# Cleanup Old Catalog Files
			if (Test-Path "$DownloadFolder\DriverPackCatalog.cab") {
				Remove-Item -Path "$DownloadFolder\DriverPackCatalog.cab" -Force -Verbose | Out-Null
			}
			if (Test-Path "$DownloadFolder\DriverPackCatalog.xml") {
				Remove-Item -Path "$DownloadFolder\DriverPackCatalog.xml" -Force -Verbose | Out-Null
			}
		
		
			# Download Driver CAB to a temp directory for processing
			Write-Verbose "Downloading Catalog: $DriverCatalog"
			Invoke-WebRequest -Uri $DriverCatalog -OutFile "$DownloadFolder\DriverPackCatalog.cab" -UseBasicParsing
			if (!(Test-Path "$DownloadFolder\DriverPackCatalog.cab")) {
				Write-Warning "Download Failed. Exiting Script."
				Exit
			}
		
			# Extract Catalog XML File from CAB
			write-Verbose "Extracting Catalog XML to $DownloadFolder"
			$CatalogCABFile = "$DownloadFolder\DriverPackCatalog.cab"
			$CatalogXMLFile = "$DownloadFolder\DriverPackCatalog.xml"
			EXPAND $CatalogCABFile $CatalogXMLFile | Out-Null
		
		}
		else {
			if (!(Test-Path -Path $DriverCatalog)) {
				Write-Warning "$DriverCatalog Does Not Exist!"
				Exit
			}
			
			$CatalogXMLFile = "$DownloadFolder\DriverPackCatalog.xml"
			Write-Verbose "Extracting DriverPackCatalog.xml to $DownloadFolder"
			EXPAND $DriverCatalog $CatalogXMLFile | Out-Null
		}
	
	Write-Verbose "Target Model: $TargetModel"
	if ($TargetOS) {
		Write-Verbose "Target Operating System(s): $($TargetOS -join ', ')"
	}	
	}# /BEGIN
	Process {
		# Import Catalog XML
		Write-Verbose "Importing Catalog XML"
		[XML]$Catalog = Get-Content $CatalogXMLFile
	
	
		# Gather Common Data from XML
		$BaseURI = "http://$($Catalog.DriverPackManifest.baseLocation)"
		$CatalogVersion = $Catalog.DriverPackManifest.version
		Write-Verbose "Catalog Version: $CatalogVersion"
	
	
		# Create Array of Driver Packages to Process
		[array]$DriverPackages = $Catalog.DriverPackManifest.DriverPackage
	
		Write-Verbose "Begin Processing Driver Packages"
		# Process Each Driver Package
		foreach ($DriverPackage in $DriverPackages) {
			#Write-Verbose "Processing Driver Package: $($DriverPackage.path)"
			$DriverPackageVersion = $DriverPackage.dellVersion
			$DriverPackageDownloadPath = "$BaseURI/$($DriverPackage.path)"
			$DriverPackageName = $DriverPackage.Name.Display.'#cdata-section'.Trim()
		
			if ($DriverPackage.SupportedSystems) {
				$Brand = $DriverPackage.SupportedSystems.Brand.Display.'#cdata-section'.Trim()
				$Model = $DriverPackage.SupportedSystems.Brand.Model.Display.'#cdata-section'.Trim()
			}
		
		# Check for matching Target Operating System
		if ($TargetOS) {
			$osMatchFound = $false
			# Look at Target Operating Systems for a match
			foreach ($SupportedOS in $DriverPackage.SupportedOperatingSystems.OperatingSystem) {
				foreach ($OS in $TargetOS) {
					if ($SupportedOS.osCode -eq $OS) {
						Write-Verbose "OS Match Found: $OS for package $DriverPackageName"
						$osMatchFound = $true
						break
					}
				}
				if ($osMatchFound) { break }
			}
		}		
			# Check for matching Target Model (Not Required for WinPE)
			if ($TargetModel -ne "WinPE") {
				$modelMatchFound = $false
				If ("$Brand $Model" -eq $TargetModel) {
					#Write-Debug "Target Model Match Found: $TargetModel"
					$modelMatchFound = $true
				}
			}
		
		
			# Check Download Condition Based on Input (Model/OS Combination)
			if ($TargetOS -and ($TargetModel -ne "WinPE")) {
				# We are looking for a specific Model/OS Combination
				if ($modelMatchFound -and $osMatchFound) { $downloadApproved = $true }
				else { $downloadApproved = $false }
			}
			elseif ($TargetModel -ne "WinPE" -and (-Not ($TargetOS))) {
				# We are looking for all Model matches
				if ($modelMatchFound) { $downloadApproved = $true }
				else { $downloadApproved = $false }
			}
			else {
				# We are looking for all OS matches
				if ($osMatchFound) { $downloadApproved = $true }
				else { $downloadApproved = $false }
			}
		
		
			if ($downloadApproved) {
			
				# Create Driver Download Directory
				if ($Brand -and $Model) {
					$DownloadDestination = "$DownloadFolder\$Brand $Model"
				}
				else {
					# Use first target OS for folder name when no model specified
					$DownloadDestination = "$DownloadFolder\$($TargetOS[0])"
				}
				if (!(Test-Path $DownloadDestination)) {
					Write-Verbose "Creating Driver Download Folder: $DownloadDestination"
					New-Item -Path $DownloadDestination -ItemType Directory -Force | Out-Null
				}
			
			
			# Download Driver Package
			if (!(Test-Path "$DownloadDestination\$DriverPackageName")) {
				Write-Verbose "Beginning File Download: $DownloadDestination\$DriverPackageName\"
			
				try {
					Invoke-WebRequest -Uri $DriverPackageDownloadPath -OutFile "$DownloadDestination\$DriverPackageName" -UseBasicParsing
				
					if (Test-Path "$DownloadDestination\$DriverPackageName") {
						Write-Verbose "Driver Download Complete: $DownloadDestination\$DriverPackageName"
					
						# Expand Driver CAB
						$ExpandPath = "$DownloadDestination\$($DriverPackageName -replace '\.cab$','')"
						Write-Verbose "Expanding Driver CAB to: $ExpandPath"
					
						# Create destination folder if it doesn't exist
						if (!(Test-Path $ExpandPath)) {
							New-Item -Path $ExpandPath -ItemType Directory -Force | Out-Null
						}
					
						# Use expand.exe to extract CAB contents
						& expand.exe "$DownloadDestination\$DriverPackageName" /F:* "$ExpandPath" | Out-Null
						
						if ($LASTEXITCODE -eq 0) {
							Write-Verbose "Successfully expanded CAB file"
						}
						else {
							Write-Warning "Failed to expand CAB file. Exit code: $LASTEXITCODE"
						}
					}
				}
				catch {
					Write-Warning "Failed to download $DriverPackageName : $($_.Exception.Message)"
					Write-Verbose "Download URL was: $DriverPackageDownloadPath"
				
					if ($null -ne $_.Exception.Response) {
						try {
							$statusCode = [int]$_.Exception.Response.StatusCode
							Write-Verbose "HTTP Status Code: $statusCode"
						}
						catch {
							# Ignore if we can't get the status code
						}
					}
				}
			}			
			}# Driver Download Section
		
		}
	
	
	}# /PROCESS
	End {
		Write-Verbose "Finished Processing Dell Driver Catalog"
	}# /END
}