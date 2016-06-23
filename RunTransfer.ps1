<#
.SYNOPSIS
   Transfers files using ROBOCOPY.
.DESCRIPTION
   PowerShell wrapper for ROBOCOPY. Runs ROBOCOPY to transfer files between M&P and Hybris.
   This is the main task of the Hybris Integration Process (HIP). The script uses the HIPS configuartion
   file to get execution parameters for ROBOCOPY. It also initiates monitoring processes.
.PARAMETER <paramName>
   <ConfigurationFile> Full Path of the configuration file
   <IsLocalCopyRequired> Y or N. Specify if copy of files transfered is required
.EXAMPLE
	#Example 1: Runs Transfer with Transfer.Config and requests and additional ROBOCOPY of the files to keep a copy of files transfered 
   	RunTransfer.ps1 -ConfigurationFile D:\HIP\Settings\Transfer.Config Y
#>

#Parameters
Param(
 [Parameter(Mandatory=$true,Position=1)]
  [String]$ConfigurationFile,
 [Parameter(Mandatory=$true,Position=2)]
  [String]$IsLocalCopyRequired
)

#Variables populated from the configuration file.
[string]$Active = ""
[int]$ProcessId = 0
[String]$SourcePath = ""
[String]$DestinationPath  = ""
[String]$RobocopyLog = ""
[string]$FileSector = ""
#Variables used to control execution
[String]$FileDatetime = ""
[int]$SourceFileCount = 0

#Load FileTransferFunctions
. C:\Deployment\HIP\Test\Scripts\FileTransferFunctions.ps1


#Populate variables from Configuration File, uses function from FileTransferFunctions.ps1
$Active = GetConfigProperty -path $ConfigurationFile -setting ProcessSettings -property Run
$SourcePath = GetConfigProperty -path $ConfigurationFile -setting TransferSettings -property Source
$DestinationPath = GetConfigProperty -path $ConfigurationFile -setting TransferSettings -property Destination
$ProcessId = GetConfigProperty -path $ConfigurationFile -setting ProcessSettings -Property ProcessId
$CopyDestination = GetConfigProperty -path $ConfigurationFile -setting TransferSettings -property CopyTo
$RobocopyLog = GetConfigProperty  -path $ConfigurationFile -setting ProcessSettings -property LogFileLocation
$RobocopyCopyActionLog = GetConfigProperty  -path $ConfigurationFile -setting ProcessSettings -property LogFileLocationCopyAction
$FileSector = GetConfigProperty -path $ConfigurationFile -setting TransferSettings -property File

#Formated date and time used in generating Logfile names
$FileDatetime = (Get-Date ).ToUniversalTime().ToString("yyyyMMddThhmmssZ")

#File Selection
$FileSector = "Load*.*"


#check transfer is active , this is a value set in the configuration file
if ($Active -eq "No")
    #action taken if transfer is not active
    { write-host "Transfer is not activiated" }
elseif ($Active -eq "Yes")
    {
		$SourceFileCount = (Get-ChildItem $SourcePath | 
								Measure-Object).Count
		$SourceFileSize = (Get-ChildItem $SourcePath -Filter "*.*" | 
								Measure-Object -Property length -Sum)
		# Format combined file size
		# Format for MByte: $size = "{0:N2}" -f ($SourceFileSize.Sum / 1MB) + " MB"
		$SourceFileSizeFormatted = "{0:N2}" -f ($SourceFileSize.Sum / 1KB)

		#Initiate Monitoring process, cals function from FileTRansferFunctions.ps1
		$HistoryId = LogTransferProcess -FileCount $SourceFileCount -ProcessId $ProcessId -FileSize $SourceFileSizeFormatted -FileSource $SourcePath -FileDestination $DestinationPath 

		#Create logfile name. Name includes current date and time to produce unique log names
		$RobocopyLog = $RobocopyLog + $FileDatetime + ".log"
		$RobocopyCopyActionLog = $RobocopyCopyActionLog + $FileDatetime + ".log"

		# Check there are files to transfer. If there are then run ROBOCOPY commands
		if ($SourceFileCount -gt 0 )
		{ 
			#Is a local copy of the files transfered needed
			if ($IsLocalCopyRequired -eq "Y")
				{
					
					#First ROBOCOPY copies the files for processing
					ROBOCOPY $SourcePath $FileSector $DestinationPath /MT:32 /LOG:$RobocopyLog 
					#Second ROBOCOPY moves (deletes from source) files to a copy location
					ROBOCOPY $SourcePath $FileSector $CopyDestination /MOV /MT:32 /LOG:$RobocopyCopyActionLog
				}
			elseif ($IsLocalCopyRequired -eq "N")
				{
					ROBOCOPY $SourcePath $FileSector $DestinationPath /MOV /MT:32 /LOG:$RobocopyLog
				}
			#Update monitoring log
			LogUpdateTransferEnd -HistoryId $HistoryId -LogFile $RobocopyLog
		}#run if files exist
		#Action if no files to transfer
		else
		{
    		LogUpdateTransferEnd -HistoryId $HistoryId -LogFile "no files"
 		} #run no files 
 
 	}#run if active





