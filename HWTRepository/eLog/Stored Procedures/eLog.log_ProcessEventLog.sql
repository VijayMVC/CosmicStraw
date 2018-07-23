CREATE	PROCEDURE eLog.log_ProcessEventLog
			(
				@pProcID			int
			  , @pMessage			nvarchar(2048)
			  , @pSeverity			tinyint			=	16
			  , @pMessageID			varchar(36)		=	NULL
			  , @pRaiserror			bit				=	NULL
			  , @pErrorNumber		int				=	NULL
			  , @pErrorProcedure	sysname			=	NULL
			  , @pErrorLine			int				=	NULL
			  , @p1					sql_variant		=	NULL
			  , @p2					sql_variant		=	NULL
			  , @p3					sql_variant		=	NULL
			  , @p4					sql_variant		=	NULL
			  , @p5					sql_variant		=	NULL
			  , @p6					sql_variant		=	NULL
			  , @pErrorData			xml				=	NULL
			  , @pLogID				bigint			=	NULL OUTPUT
			)
/*
***********************************************************************************************************************************

	Procedure:	eLog.log_ProcessEventLog
	 Abstract:	processes inbound event for EventLog
				format inbound SQL error, log error to tables, return error messages


	Logic Summary
	-------------
	1)	Replace parameter holders in @pMessage by converting parameter values to strings
	2)	Set values for username, accounting for impersonation.
	3)	log error message to eLog.EventLog
	4)	Raise the error, depending on input parameters and severity


	Parameters
	----------
	@pProcID			int				inbound procid ( generally from @@PROCID )
	@pMessage			nvarchar(2048)	formatted message text with parameters
	@pSeverity			tinyint			usually from ERROR_SEVERITY(), can be selected, cannot be higher than 16
	@pMessageID			varchar(36)		error message id ( if included )
	@pRaiserror			bit				indicator, raise error on severity, always raise, or never raise
	@pErrorNumber		int				SQL error number
	@pErrorProcedure	sysname			calling procedure name for logging
	@pErrorLine			int				line in which code was thrown
	@p1					sql_variant		formatted parameters from error message
	@p2					sql_variant		formatted parameters from error message
	@p3					sql_variant		formatted parameters from error message
	@p4					sql_variant		formatted parameters from error message
	@p5					sql_variant		formatted parameters from error message
	@p6					sql_variant		formatted parameters from error message
	@pErrorData			xml				relevant internals from captured error
	@pLogID				bigint			return key for error that was logged

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

  This is the official interface to log a message to SqlEventLog. An
  application may want wrap this to add it's own rules. By default
  invokes RAISERROR if severity is >= 11.

  Parameters:
  @procid	 - Always pass @@procid (save for wrappers).
  @msgtext	 - Text for the message, may be parameterised.
  @severity	 - Severity for message, default 16.
  @msgid	 - Message id, defined in slog.usermessages or ad hoc.
  @raiserror - NULL => Raise only if @severity >= 11. 0 => Never
			   raise. 1 => Always raise.
  @errno	 - Error number to log, mainly for catchhandler_sp.
  @errproc	 - Name of procedure to log, mainly for catchhandler_sp.
  @linenum	 - Line number to log, mainly for catchhandler_sp.
  @p1 to @p6 - Parameters for %1 to %6 i @msgtext.
  @logid	 - Returns the key for logged message in slog.sqleventlog.

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@str1		nvarchar(4000)
			  , @str2		nvarchar(4000)
			  , @str3		nvarchar(4000)
			  , @str4		nvarchar(4000)
			  , @str5		nvarchar(4000)
			  , @str6		nvarchar(4000)
			  , @username	sysname
			  , @appname	nvarchar(128)	=	APP_NAME()
			  , @hostname	nvarchar(128)	=	HOST_NAME()
			  , @dbname		sysname			=	DB_NAME()
			  , @logSPName	nvarchar(200)	=	'LOOPBACK.' + QUOTENAME( DB_NAME() ) + '.eLog.log_InsertEvent'
			  , @userlang	smallint
			  , @syslang	smallint
			  , @usermsg	nvarchar(2048)
				;


--	1)	Replace parameter holders in @pMessage by converting parameter values to strings
	IF	( @pMessage IS NOT NULL )
	BEGIN
		  EXECUTE	eLog.log_ExpandParameters
						@pMessageIO =	@pMessage	OUTPUT
					  , @pParamNum	=	1
					  , @pVariantIn =	@p1
					  , @pStringOut =	@str1		OUTPUT
					;

		  EXECUTE	eLog.log_ExpandParameters
						@pMessageIO =	@pMessage	OUTPUT
					  , @pParamNum	=	2
					  , @pVariantIn =	@p2
					  , @pStringOut =	@str2		OUTPUT
					;

		  EXECUTE	eLog.log_ExpandParameters
						@pMessageIO =	@pMessage	OUTPUT
					  , @pParamNum	=	3
					  , @pVariantIn =	@p3
					  , @pStringOut =	@str3		OUTPUT
					;

		  EXECUTE	eLog.log_ExpandParameters
						@pMessageIO =	@pMessage	OUTPUT
					  , @pParamNum	=	4
					  , @pVariantIn =	@p4
					  , @pStringOut =	@str4		OUTPUT
					;

		  EXECUTE	eLog.log_ExpandParameters
						@pMessageIO =	@pMessage	OUTPUT
					  , @pParamNum	=	5
					  , @pVariantIn =	@p5
					  , @pStringOut =	@str5		OUTPUT
					;

		  EXECUTE	eLog.log_ExpandParameters
						@pMessageIO =	@pMessage	OUTPUT
					  , @pParamNum	=	6
					  , @pVariantIn =	@p6
					  , @pStringOut =	@str6		OUTPUT
					;
	END

	ELSE

		  SELECT @pMessage = 'Error has occurred, but there is no error message provided' ;


--	2)	Set values for username, accounting for impersonation.
	  SELECT	@username	=	CASE
									WHEN SYSTEM_USER = ORIGINAL_LOGIN() OR ISNULL( ORIGINAL_LOGIN(), '' ) = '' THEN SYSTEM_USER
									ELSE CONVERT( nvarchar(60), SYSTEM_USER ) + ' (' + CONVERT( nvarchar(60), ORIGINAL_LOGIN() ) + ')'
								END
				;


--	3)	log error message to eLog.EventLog
	IF	( @@TRANCOUNT = 0 )
	BEGIN
		--	code was not invoked inside a transaction
		--	invoke eLog.log_InsertEvent directly
		 EXECUTE	eLog.log_InsertEvent
						@pLogID				=	@pLogID OUTPUT
					  , @pMessageID			=	@pMessageID
					  , @pErrorNumber		=	@pErrorNumber
					  , @pSeverity			=	@pSeverity
					  , @pLoggingProcID		=	@pProcID
					  , @pMessage			=	@pMessage
					  , @pErrorProcedure	=	@pErrorProcedure
					  , @pErrorLine			=	@pErrorLine
					  , @pUserName			=	@username
					  , @pAppName			=	@appname
					  , @pHostName			=	@hostname
					  , @p1					=	@str1
					  , @p2					=	@str2
					  , @p3					=	@str3
					  , @p4					=	@str4
					  , @p5					=	@str5
					  , @p6					=	@str6
					  , @pErrorData			=	@pErrorData
					;
	END

	ELSE

	BEGIN
		--	code was invoked inside a transaction
		--	invoke eLog.log_InsertEvent via loopback
		 EXECUTE	@logSPName
						@pLogID				=	@pLogID OUTPUT
					  , @pMessageID			=	@pMessageID
					  , @pErrorNumber		=	@pErrorNumber
					  , @pSeverity			=	@pSeverity
					  , @pLoggingProcID		=	@pProcID
					  , @pMessage			=	@pMessage
					  , @pErrorProcedure	=	@pErrorProcedure
					  , @pErrorLine			=	@pErrorLine
					  , @pUserName			=	@username
					  , @pAppName			=	@appname
					  , @pHostName			=	@hostname
					  , @p1					=	@str1
					  , @p2					=	@str2
					  , @p3					=	@str3
					  , @p4					=	@str4
					  , @p5					=	@str5
					  , @p6					=	@str6
					  , @pErrorData			=	@pErrorData
					;
	END


--	4)	Raise the error, depending on input parameters and severity
	IF	( @pRaiserror = 1 ) OR ( @pRaiserror IS NULL AND @pSeverity >= 11 )
	BEGIN

		-- prepare a message. The RAISERROR itself is outside the TRY block.
		SELECT @pRaiserror = 1 ;

		-- If there is a message id, look it up and see if there is a message
		-- directed towards the user in his own language.
		IF	( @pMessageID IS NOT NULL )
		BEGIN
				-- Get the language ids to use.
			  SELECT	@userlang	=	lcid
				FROM	master.sys.syslanguages
			   WHERE	langid		=	@@langid
						;


			  SELECT	@syslang = l.lcid
				FROM	master.sys.configurations AS c
						INNER JOIN master.sys.syslanguages AS l
								ON c.value_in_use = l.langid

			   WHERE	c.configuration_id = 124
						;


				-- Get the user message
			  SELECT	TOP 1
						@usermsg	=	MessageText
				FROM	eLog.UserMessage
			   WHERE	MessageID	=	@pMessageID AND LCID IN ( @userlang, @syslang )
			ORDER BY	CASE LCID
							WHEN @userlang THEN 1
							WHEN @syslang THEN 2
						END
						;

				-- substitute parameters into the user message
			IF	( @usermsg IS NOT NULL )
			BEGIN
				 EXECUTE	eLog.log_ExpandParameters
								@pMessageIO =	@usermsg OUTPUT
							  , @pParamNum	=	1
							  , @pVariantIn =	@p1
							;

				 EXECUTE	eLog.log_ExpandParameters
								@pMessageIO =	@usermsg OUTPUT
							  , @pParamNum	=	2
							  , @pVariantIn =	@p2
							;

				 EXECUTE	eLog.log_ExpandParameters
								@pMessageIO =	@usermsg OUTPUT
							  , @pParamNum	=	3
							  , @pVariantIn =	@p3
							;

				 EXECUTE	eLog.log_ExpandParameters
								@pMessageIO =	@usermsg OUTPUT
							  , @pParamNum	=	4
							  , @pVariantIn =	@p4
							;

				 EXECUTE	eLog.log_ExpandParameters
								@pMessageIO =	@usermsg OUTPUT
							  , @pParamNum	=	5
							  , @pVariantIn =	@p5
							;

				 EXECUTE	eLog.log_ExpandParameters
								@pMessageIO =	@usermsg OUTPUT
							  , @pParamNum	=	6
							  , @pVariantIn =	@p6
							;

			END
		END

		-- If we have no user message, use @pMessage.
		SELECT @usermsg = ISNULL( @usermsg, @pMessage ) ;

	END

	RETURN 0 ;

END TRY

BEGIN CATCH

	--	This should not occur.
	--	Convey error from here and original error message
	  SELECT	@pRaiserror =	1
			  , @pSeverity	=	16
			  , @usermsg	=	'eLog.log_ProcessEventLog failed with '
									+ SUBSTRING( ERROR_MESSAGE(), 1, 800)
									+ CHAR(13) + CHAR(10)
									+ 'Original error message was: '
									+ @pMessage
				;

	-- Avoid new error if transaction is doomed.
	IF	( XACT_STATE() = -1 ) ROLLBACK TRANSACTION ;

END CATCH

IF	( @pRaiserror = 1 )
BEGIN
	-- Do not allow severity > 16.
	IF	( @pSeverity > 16 ) SELECT @pSeverity	= 16 ;

	RAISERROR( '%s', @pSeverity, 1, @usermsg ) WITH NOWAIT ;

END

