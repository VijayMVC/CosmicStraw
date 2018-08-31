CREATE PROCEDURE
	eLog.log_CatchProcessing
		(
			@pProcID		int				=	NULL
		  , @pReraise		bit				=	1
		  , @pError_Number	int				=	NULL	OUTPUT
		  , @pMessage		nvarchar(2048)	=	NULL	OUTPUT
		  , @pMessage_aug	nvarchar(2048)	=	NULL	OUTPUT
		  , @pErrorData		xml				=	NULL
		)
/*
***********************************************************************************************************************************

  Procedure:	eLog.log_CatchProcessing
   Abstract:	error handling process that goes into CATCH block for code


	Logic Summary
	-------------
	1)	Rollback transaction if required ( Sommarskog, Part Three, section 2.3 )
	2)	Assign output parameters
	3)	Process error, accounting for re-raised errors and original errors


	Parameters
	----------
	@pProcID		int				object_id for calling object
	@pReraise		bit				whether or not handler should re-raise error
										useful for loops where single iteration
										could error but intended behavior is to
										process entire loop
	@pError_Number	int				original error number
	@pMessage		nvarchar(2048)	original error message
	@pMessage_aug	nvarchar(2048)	enhanced error message containing name of
										calling object and line number of error
	@pErrorData		xml				contains relevant internals from error


	Notes
	-----
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )

	Revision
	--------
	carsoc3		2018-03-15		Added to alpha release
	carsoc3		2018-08-31		enhanced error handling


	Original comments

	This stored procedure intended to be called from a CATCH handler.
	The procedure logs the error to sqleventlog, by default it reraises
	the error.

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@crlf				char(2)			=	CHAR(13) + CHAR(10)
			  , @error_message		nvarchar(2048)	=	ERROR_MESSAGE()
			  , @error_number		int				=	ERROR_NUMBER()
			  , @error_procedure	sysname			=	ERROR_PROCEDURE()
			  , @error_line			int				=	ERROR_LINE()
			  , @error_severity		int				=	ERROR_SEVERITY()
			  , @error_state		int				=	ERROR_STATE()
			  , @temperrno			varchar(9)
				;


--	1)	Rollback transaction if required ( Sommarskog, Part Three, section 2.3 )
	IF	( @@trancount > 0 ) ROLLBACK TRANSACTION ;


--	2)	Assign output parameters
	  SELECT	@pError_Number	=	@error_number
			  , @pMessage		=	@error_message
				;


--	3)	Process error, accounting for re-raised errors and original errors
	--	check for source of error, did it come from external code, or from a script?
	IF	( ISNULL( @error_procedure, '' ) NOT IN ( N'log_CatchProcessing', N'log_ProcessEventLog' ) )
			OR
		( @error_line = 0 )
	BEGIN
		--	process an original error passed into the catch handler externally
		--		log the error by calling eLog.log_ProcessEventLog
		--		specify @pRaiserror = 0 so that error is not re-raised in eLog.log_ProcessEventLog
		 EXECUTE	eLog.log_ProcessEventLog
						@pProcID			=	@pProcID
					  , @pMessage			=	@error_message
					  , @pRaiserror			=	0
					  , @pSeverity			=	@error_severity
					  , @pErrorNumber		=	@error_number
					  , @pErrorProcedure	=	@error_procedure
					  , @pErrorLine			=	@error_line
					  , @pErrorData			=	@pErrorData
					;

		--	augment error message.	Include message number, procedure and line number
		  SELECT	@pMessage_aug	=	'{' + LTRIM( STR( @error_number ) ) + '}'
											+ ISNULL( ' Procedure ' + @error_procedure + ',' , ',' )
											+ ' Line ' + LTRIM( STR( @error_line ) ) + @crlf
											+ @error_message
					;
	END

	ELSE
	BEGIN
		--	this is NOT an original error, or it is a script error
		IF	( @error_message LIKE '{[0-9]%}%' + @crlf + '%' )
				AND CHARINDEX( '}', @error_message ) BETWEEN 3 AND 11

		BEGIN
		--	this is a re-raised error previously formatted by error processing routines
		--		extract the original error number.
			SELECT @temperrno = SUBSTRING( @error_message, 2, CHARINDEX( '}', @error_message ) - 2 ) ;
			IF	( @temperrno NOT LIKE '%[^0-9]%' )
				SELECT @error_number = CONVERT( INT, @temperrno ) ;

		--		Write to the two output variables for the error message.
			SELECT		@pMessage		=	SUBSTRING( @error_message, CHARINDEX( @crlf, @error_message ) + 2, LEN( @error_message ) )
					  , @pMessage_aug	=	@error_message
						;
		END

		ELSE
		BEGIN
		--	Presumably a message raised by calling eLog.log_ProcessEventLog directly.
			SELECT		@pMessage		=	@error_message
					  , @pMessage_aug	=	@error_message
						;
		END
	END
END TRY

BEGIN CATCH
	--	this block should not occur
	--		produce original error and error from this proc
	--
	--		handle message from eLog.log_ProcessEventLog as is
	--		that message *should* contain original error message

	 DECLARE	@newerr nvarchar(2048)	=	ERROR_MESSAGE() ;
	  SELECT	@pReraise		=	1
			  , @error_message	=	CASE
										WHEN	@newerr LIKE 'eLog.log_ProcessEventLog%' THEN @newerr
										ELSE	'eLog.log_CatchProcessing failed with '
													+ @newerr
													+ @crlf
													+ 'Original error: '
													+ @error_message
									END
				;

	--	Set output variables if this has not been done.
	  SELECT	@pMessage		=	ISNULL( @pMessage, @error_message )
			  , @pMessage_aug	=	ISNULL( @pMessage_aug, @error_message )
				;

   -- Avoid new error if transaction is doomed.
	IF	( XACT_STATE() = -1 ) ROLLBACK TRANSACTION ;

END CATCH

-- Raise error if requested ( or if an unexepected error occurred ).
IF	( @pReraise = 1 )
BEGIN

	--	Adjust severity if needed; plain users cannot raise level 19.
	IF	( @error_severity > 18 ) SELECT @error_severity = 18 ;

	RAISERROR( '%s', @error_severity, @error_state, @pMessage_aug ) ;

END

RETURN 0 ;
