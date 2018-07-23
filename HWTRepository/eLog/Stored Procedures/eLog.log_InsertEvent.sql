CREATE	PROCEDURE eLog.log_InsertEvent
			(
				@pLogID				bigint OUTPUT
			  , @pMessageID			varchar(255)
			  , @pErrorNumber		int
			  , @pSeverity			tinyint
			  , @pLoggingProcID		int
			  , @pMessage			nvarchar(2048)
			  , @pErrorProcedure	sysname
			  , @pErrorLine			int
			  , @pUserName			sysname
			  , @pAppName			sysname
			  , @pHostName			sysname
			  , @p1					nvarchar(4000)
			  , @p2					nvarchar(4000)
			  , @p3					nvarchar(4000)
			  , @p4					nvarchar(4000)
			  , @p5					nvarchar(4000)
			  , @p6					nvarchar(4000)
			  , @pErrorData			xml
			)
/*
***********************************************************************************************************************************

	Procedure:	eLog.log_InsertEvent
	 Abstract:	create event on eLog.EventLog


	Logic Summary
	-------------
	1)	Translate @pLoggingProcID to a name.
	2)	Format and insert into eLog.EventLog
	3)	Log all parameter values.


	Parameters
	----------
	@pLogID				bigint			key for inserted record
	@pMessageID			varchar(255)	message id for error
	@pErrorNumber		int				SQL Error code
	@pSeverity			tinyint			severity
	@pLoggingProcID		int				SPID for process that threw the error
	@pMessage			nvarchar(2048)	expanded message text
	@pErrorProcedure	sysname			procedure name from calling program
	@pErrorLine			int				line number in proc that threw the error
	@pUserName			sysname			user name
	@pAppName			nvarchar(128)	application name
	@pHostName			nvarchar(128)	computer from which code executed
	@p1					nvarchar(4000)	input parameters for error message, translated to string
	@p2					nvarchar(4000)	input parameters for error message, translated to string
	@p3					nvarchar(4000)	input parameters for error message, translated to string
	@p4					nvarchar(4000)	input parameters for error message, translated to string
	@p5					nvarchar(4000)	input parameters for error message, translated to string
	@p6					nvarchar(4000)	input parameters for error message, translated to string
	@pErrorData			xml				relevant internals from captured error

	Notes
	-----
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )

	Revision
	--------
	carsoc3		2018-02-20		Added to alpha release
	carsoc3		2018-04-27		Original production release
	carsoc3		2018-08-31		enhanced error handling

	Original comments

	This procedure performs the actual insert into the table slog.sqleventlog.
	It is not intended to be called directly, but only from sqleventlog_sp,
	possibly through a loopback arrangement. Note that this procedure
	assumes that parameter holders in @msgtext have been expanded, and that
	@username, @appname and @hostname have the correct values (it would not
	be possible for log_insert_sp to retrieve these when called in a loopback.)

***********************************************************************************************************************************
*/
AS
SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@logProc	nvarchar(257) ;

--	1)	Translate @pLoggingProcID to a name.
	 EXECUTE	eLog.log_GetProcID
					@pProcID	=	@pLoggingProcID
				  , @pProcName	=	@logProc		OUTPUT
				;


--	2)	Format and insert into eLog.EventLog
	--	The COALESCE statements standardize input from calling procs where the input format may not be known.
	  INSERT	eLog.EventLog
					(
						MessageID, ErrorNumber, Severity, LoggingProc, FullMessage, ErrorProc
							, LineNumber, UserName, AppName, HostName, ErrorData
					)

	  SELECT	MessageID	=	@pMessageID
			  , ErrorNumber =	@pErrorNumber
			  , Severity	=	COALESCE( @pSeverity, 16 )
			  , LoggingProc =	@logProc
			  , FullMessage =	COALESCE( @pMessage, 'NO MESSAGE PROVIDED' )
			  , ErrorProc	=	@pErrorProcedure
			  , LineNumber	=	@pErrorLine
			  , UserName	=	COALESCE( @pUserName, SYSTEM_USER )
			  , AppName		=	@pAppName
			  , HostName	=	@pHostName
			  , ErrorData	=	@pErrorData
				;

	  SELECT @pLogID = SCOPE_IDENTITY() ;


--	3)	Log all parameter values.

	  INSERT	INTO eLog.EventLogParameter
					( EventLogID, ParamNum, ParamValue )
	  SELECT	EventLogID	=	@pLogID
			  , ParamNum	=	paramNum
			  , ParamValue	=	paramValue
		FROM	(
				  VALUES	( 1, @p1 )
						  , ( 2, @p2 )
						  , ( 3, @p3 )
						  , ( 4, @p4 )
						  , ( 5, @p5 )
						  , ( 6, @p6 )
				) AS x( paramNum, paramValue )
	   WHERE	x.paramValue IS NOT NULL ;

	RETURN 0 ;

END TRY

BEGIN CATCH

	-- Hopefully we never come here...
	DECLARE @msg nvarchar(2048) ;

	IF	( XACT_STATE() = -1 ) ROLLBACK TRANSACTION ;

	  SELECT	@msg	=	'eLog.log_InsertEvent failed with "'
								+ ERROR_MESSAGE()
								+ '". '
								+ 'Original error was: '
								+ @pMessage
				;

	RAISERROR( '%s', 16, 1, @msg ) ;

END CATCH

