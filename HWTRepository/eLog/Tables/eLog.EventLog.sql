CREATE TABLE 	eLog.EventLog 
/*
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP 
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )

	notes are based from original author
	
	Revisions
	
	2018-04-27		carsoc3		Initial production launch
	2018-06-30		carsoc3		Added DataID to support HW Test Data Manager changes
									DataID can be either HeaderID or VectorID
*/
	(
		EventLogID		bigint			NOT NULL		IDENTITY
	  , LogDate			datetime2(7)	NOT NULL		DEFAULT sysdatetime()	
	  , MessageID		nvarchar(36)					-- used with localisation and custom errors.
	  , DataID			int								
	  , ErrorNumber		int								-- SQL Server error_number().
	  , Severity		tinyint			NOT NULL		-- SQL Server error_severity(), can bu.
	  , LoggingProc		nvarchar(257)					-- Procedure that that called error handler routine.
	  , ErrorProc		sysname							-- Procedure that raised error ( different than LoggingProcedure )
	  , FullMessage		nvarchar(2048)	NOT NULL		-- Message text with parameters expanded.
	  , LineNumber		int								-- Line number in procedure.
	  , UserName		sysname			NOT NULL		-- From original_login/SYSTEM_USER.
	  , AppName			sysname							-- From app_name().
	  , HostName		sysname							-- From host_name().

	  , CONSTRAINT PK_eLog_EventLog 
			PRIMARY KEY NONCLUSTERED( EventLogID ASC )
	) ; 
GO

CREATE CLUSTERED INDEX 	
	IX_eLog_EventLog_LogDate 
		ON eLog.EventLog( LogDate ASC ) ; 
