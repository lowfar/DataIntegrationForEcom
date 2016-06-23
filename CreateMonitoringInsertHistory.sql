USE [Mercury]
GO


/***
AUTHOR: Matthew Haigh
DATE: 4 February 2016
CALLING APPLICATION: PowerShell scripts
NOTES: Stores history of file transfers
***/

CREATE PROC [Monitoring].[InsertHistory]
	(
		@ProcessId BIGINT,
		@ProcessingDate DATETIME,
		@FileCount INT,
		@FileSize DECIMAL(19,4),
		@FileSource VARCHAR(150),
		@FileDestination VARCHAR(150),
		@OutputLoadId BIGINT OUTPUT
) AS
BEGIN TRANSACTION
	INSERT INTO Monitoring.History
	        ( 
	          ProcessId ,
	          TransferStart ,
	          FileCount,
			  Size,
			  FileSource,
			  FileDestination
	        )
	VALUES  (
	          @ProcessId , -- ProcessId - bigint
	          @ProcessingDate, -- TransaferDate - datetime
	          @FileCount,  -- FileCount - int
			  @FileSize,
			  @FileSource,
			  @FileDestination
	        )

 SET @OutputLoadId = @@IDENTITY
COMMIT;


GO

EXEC sys.sp_addextendedproperty 
	@name=N'MS_Description', 
	@value=N'Called from Powershell scripts to insert a log each time a file transfer is executed. Output parameter returns the HistoryId' , 
	@level0type=N'SCHEMA',
	@level0name=N'Monitoring', 
	@level1type=N'PROCEDURE',
	@level1name=N'InsertHistory'
GO


