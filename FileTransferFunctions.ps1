<#
.SYNOPSIS
   Contains the PowerShell Functions called during the Transfer Process. 
   Functions include stripping of configuration files to get property values and execution of SQL Server commands.
.DESCRIPTION
   Functions required during the transfer of files. 
   The functions facilitate the setting of transfer parameters:
	*Source
	*Destination
	*Log File Location
   Enable the monitoring of the transfer process by updating SQL Server by executing Stored Procedures .
#>

<#
.AUTHOR
	Matthew Haigh, DBA Team, IT Operations
.FUNCTION
	GetConfigProperty
.SYNOPSIS
   Extracts property values from the configuration file passed to the function using the $path parameter. 
.DESCRIPTION
   Extracts node values from an XML file. e.g. <Source>10</Source>, function would return [10]. 
   The file being 'stripped' must be a correctly formatted XML file.
.PARAMETER <paramName>
   $path: Full file path of the Configuration File
   $setting: <TransferSetting>
   				<Source>10</Source>
			 </TransferSetting>
			 Identifies the setting from which to strip the properties
   $property: Property value required
.EXAMPLE
   $SourcePath = GetConfigProperty -path C:\example.config -setting TransferSettings -property Source
#>
Function GetConfigProperty ($path , $setting, $property )
{
	# Check config file exists
   $FileExists = Test-Path $path
   if ($FileExists -eq $true)
    {
       # Get contents of config file
       $config = [xml](Get-Content $path)
       $config.Configuration.$setting.$property
    }
    else { 
            Write-Error -Message "Config File $path does not exist" -Category ObjectNotFound 
            
         }
     
}

<#
.AUTHOR
   Matthew Haigh, DBA Team, IT Operations
.SYNOPSIS
   Function to log file transfer process in SQL Server Database using stored procedure
.DESCRIPTION
   Executes Stored Procedure, passing the required parameters. Makes the Stored Procedure OUTPUT
   parameter available to be used by the calling script.
.PARAMETER <paramName>
   $ProcessId: 	The Unique ProcessId of the Transfer Process being run. 
   				This will be passed from the calling PowerShell script, whether hard coded or taken from a config file
   $FileCount: 	Number of files to be transfered
   $FileSize: 	Combined size of the files to be moved
   $FileSource:	Network path
   $FileDestination: Network path
.EXAMPLE
   LogTransferProcess -FileCount $SourceFileCount -ProcessId $ProcessId -FileSize $SourceFileSizeFormatted -FileSource $SourcePath -FileDestination $DestinationPath 
#>
Function LogTransferProcess ($ProcessId, $FileCount, $FileSize, $FileSource, $FileDestination)
{
$SQLServer = "MPHYBRISTEST01"
$SQLDBName = "Mercury"
$SQLQuery = "Monitoring.InsertHistory"

[long]$LoadId = 0

$SQLConnection = New-Object System.Data.SqlClient.SqlConnection
$SQLConnection.ConnectionString = "Server=$SQLServer; Database=$SQLDBName; Integrated Security=True"

$SQLConnection.Open()

$SQLCmd = New-Object System.Data.SqlClient.SqlCommand
$SQLCmd.CommandType = [System.Data.CommandType]::StoredProcedure
$SQLCmd.CommandText = $SQLQuery
$SQLCmd.Connection = $SQLConnection

$SQLCmd.Parameters.Add("@ProcessId", [System.Data.SqlDbType]::BigInt) | Out-Null
$SQLCmd.Parameters["@ProcessId"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@ProcessId"].Value = $ProcessId

$SQLCmd.Parameters.Add("@ProcessingDate", [System.Data.SqlDbType]::DateTime) | Out-Null
$SQLCmd.Parameters["@ProcessingDate"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@ProcessingDate"].Value = Get-Date

$SQLCmd.Parameters.Add("@FileCount", [System.Data.SqlDbType]::Int) | Out-Null
$SQLCmd.Parameters["@FileCount"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@FileCount"].Value = $FileCount

$SQLCmd.Parameters.Add("@FileSize", [System.Data.SqlDbType]::Decimal) | Out-Null
$SQLCmd.Parameters["@FileSize"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@FileSize"].Value = $FileSize

$SQLCmd.Parameters.Add("@FileSource", [System.Data.SqlDbType]::VarChar) | Out-Null
$SQLCmd.Parameters["@FileSource"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@FileSource"].Value = $FileSource

$SQLCmd.Parameters.Add("@FileDestination", [System.Data.SqlDbType]::VarChar) | Out-Null
$SQLCmd.Parameters["@FileDestination"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@FileDestination"].Value = $FileDestination

$SQLCmd.Parameters.Add("@OutputLoadId", [System.Data.SqlDbType]::BigInt) | Out-Null
$SQLCmd.Parameters["@OutputLoadId"].Direction = [System.Data.ParameterDirection]::Output

$SQLCmd.ExecuteNonQuery() | Out-Null


$output = $SQLCmd.Parameters["@OutputLoadId"].Value

return $output

$SQLConnection.Close()

}


<#
.SYNOPSIS
   Executes Stored Procedure to update the transfer monitoring table
.DESCRIPTION
   Executes stored procedure to update the transfer history with logfile details. Function
   is used at the end of the transfer process
.PARAMETER <paramName>
   $HistoryId(Int): Unique id that identifies an instance of a transfer process
   $LogFile(String): Full path of the ROBOCOPY Log File
.EXAMPLE
   LogUpdateTransferEnd -HistoryId $HistoryId -LogFile $RobocopyLog
#>
Function LogUpdateTransferEnd ($HistoryId, $LogFile)
{
$SQLServer = "MPHYBRISTEST01"
$SQLDBName = "Mercury"
$SQLQuery = "Monitoring.UpdateHistory"



$SQLConnection = New-Object System.Data.SqlClient.SqlConnection
$SQLConnection.ConnectionString = "Server=$SQLServer; Database=$SQLDBName; Integrated Security=True"

$SQLConnection.Open()

$SQLCmd = New-Object System.Data.SqlClient.SqlCommand
$SQLCmd.CommandType = [System.Data.CommandType]::StoredProcedure
$SQLCmd.CommandText = $SQLQuery
$SQLCmd.Connection = $SQLConnection

$SQLCmd.Parameters.Add("@HistoryId", [System.Data.SqlDbType]::BigInt) | Out-Null
$SQLCmd.Parameters["@HistoryId"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@HistoryId"].Value = $HistoryId

$SQLCmd.Parameters.Add("@LogFile", [System.Data.SqlDbType]::VarChar) | Out-Null
$SQLCmd.Parameters["@LogFile"].Direction = [System.Data.ParameterDirection]::Input
$SQLCmd.Parameters["@LogFile"].Value = $LogFile

$SQLCmd.ExecuteNonQuery() | Out-Null
$SQLConnection.Close()

}

