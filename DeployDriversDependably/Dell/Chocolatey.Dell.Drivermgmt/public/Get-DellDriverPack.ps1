function Get-DellDriverPack {
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

		.NOTES
		Original script from: https://deploymentramblings.wordpress.com/2014/04/17/downloading-dell-driver-cab-files-automagically-with-the-driver-pack-catalog/
   #>
	[CmdletBinding()]
	Param(
		[Parameter()]
		[String]
		$DriverCatalog = "http://downloads.dell.com/catalog/DriverPackCatalog.cab",

		[Parameter(Mandatory)]
		[String]
		$DownloadFolder,

		[Parameter()]
		[String]
		$TargetModel = "WinPE",

		[Parameter()]
		[ValidateSet("Vista", "Windows7", "Windows8", "Windows8.1", "Windows10", "Windows11", "winpe3x", "winpe4x", "winpe5x")]
		[String[]]
		$TargetOS
	)

	Begin {
	
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
		else {
			# Use the provided catalog file directly
			Write-Verbose "Using provided catalog: $DriverCatalog"
			$CatalogXMLFile = $DriverCatalog
		}
	}		Write-Verbose "Target Model: $TargetModel"
		if ($TargetOS) {
			Write-Verbose "Target Operating System(s): $($TargetOS -join ', ')"
		}	
	}# /BEGIN
	Process {
		# Import Catalog XML
		Write-Verbose "Importing Catalog XML"
		[XML]$Catalog = Get-Content $CatalogXMLFile
	
	
		# Gather Common Data from XML
		$BaseURI = "https://$($Catalog.DriverPackManifest.baseLocation)"
		$CatalogVersion = $Catalog.DriverPackManifest.version
		Write-Verbose "Catalog Version: $CatalogVersion"
		Write-Verbose "Base URI: $BaseURI"
	
	
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
				# Get the first Brand (they're usually the same for a single package)
				$FirstBrand = $DriverPackage.SupportedSystems.Brand | Select-Object -First 1
				$Brand = $FirstBrand.Display.'#cdata-section'.Trim()
			
				# Use the 'name' attribute from the first Model
				$Model = $FirstBrand.Model.name
				if (-not $Model) {
					# Fallback to Display if name attribute doesn't exist
					$Model = $FirstBrand.Model.Display.'#cdata-section'.Trim()
				}
			}		# Check for matching Target Operating System(s)
			if ($TargetOS) {
				$osMatchFound = $false
				$matchedOS = $null
				# Look at Target Operating Systems for a match
				foreach ($SupportedOS in $DriverPackage.SupportedOperatingSystems.OperatingSystem) {
					foreach ($OS in $TargetOS) {
						if ($SupportedOS.osCode -eq $OS) {
							Write-Verbose "OS Match Found: $($SupportedOS.osCode) for package $DriverPackageName"
							$osMatchFound = $true
							$matchedOS = $OS
							break
						}
					}
					if ($osMatchFound) { break }
				}
			}		
			# Check for matching Target Model (Not Required for WinPE)
			if ($TargetModel -ne "WinPE") {
				$modelMatchFound = $false
				$matchedModel = $null
				# Check all Models in all Brands for a match
				foreach ($Brand in $DriverPackage.SupportedSystems.Brand) {
					foreach ($BrandModel in $Brand.Model) {
						$ModelName = $BrandModel.name
						if (-not $ModelName) {
							$ModelName = $BrandModel.Display.'#cdata-section'.Trim()
						}
						If ($ModelName -eq $TargetModel) {
							Write-Verbose "Model Match Found: $ModelName for package $DriverPackageName"
							$modelMatchFound = $true
							$matchedModel = $ModelName
							break
						}
					}
					if ($modelMatchFound) { break }
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
			
			# Create Driver Download Directory organized by Model, then OS
			if ($matchedModel) {
				if ($matchedOS) {
					$DownloadDestination = "$DownloadFolder\$matchedModel\$matchedOS"
				}
				else {
					$DownloadDestination = "$DownloadFolder\$matchedModel"
				}
			}
			else {
				# Fallback for packages without a specific model match (e.g., WinPE)
				if ($matchedOS) {
					$DownloadDestination = "$DownloadFolder\$matchedOS"
				}
				else {
					$DownloadDestination = "$DownloadFolder"
				}
			}
			
			if (!(Test-Path $DownloadDestination)) {
				Write-Verbose "Creating Driver Download Folder: $DownloadDestination"
				New-Item -Path $DownloadDestination -ItemType Directory -Force | Out-Null
			}			
				# Download Driver Package
				if (!(Test-Path "$DownloadDestination\$DriverPackageName")) {
					Write-Verbose "Beginning File Download from: $DriverPackageDownloadPath"
					Write-Verbose "Download Destination: $DownloadDestination\$DriverPackageName"
				
					try {
						# Download with Invoke-WebRequest
						Invoke-WebRequest -Uri $DriverPackageDownloadPath -OutFile "$DownloadDestination\$DriverPackageName" -UseBasicParsing
				
						if (Test-Path "$DownloadDestination\$DriverPackageName") {
							Write-Verbose "Driver Download Complete: $DownloadDestination\$DriverPackageName"
						}
					}
					catch {
						Write-Warning "Failed to download $DriverPackageName : $($_.Exception.Message)"
						Write-Verbose "Download URL was: $DriverPackageDownloadPath"
					
						# Check if it's a 404 or other HTTP error
						if ($_.Exception.Response) {
							$statusCode = [int]$_.Exception.Response.StatusCode
							Write-Verbose "HTTP Status Code: $statusCode"
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