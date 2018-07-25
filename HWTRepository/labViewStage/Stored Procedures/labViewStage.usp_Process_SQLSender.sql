CREATE PROCEDURE labViewStage.usp_Process_SQLSender
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_Process_SQLSender
	Abstract:	SQL Sender Activator Queue

	Logic Summary
	-------------

	Parameters
	----------

	Notes
	-----

	Revision
	--------
	carsoc3		2018-08-31		added messaging architecture for labViewStage data

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

  DECLARE	@conversation_handle	uniqueidentifier
		  , @message_body			xml
		  , @response_message_body	xml
		  , @SQLStatement			nvarchar(max)
		  , @message_type_name		sysname
		  , @message_enqueue_time	datetime
		  , @error_message			nvarchar(2048)
		  , @error_number			int
			;

	WHILE	( 1 = 1 )
	BEGIN
		BEGIN TRANSACTION ;

			 WAITFOR	(
							 RECEIVE	TOP( 1 )
										@conversation_handle	=	conversation_handle
									  , @SQLStatement			=	message_body
									  , @message_type_name		=	message_type_name
									  , @message_enqueue_time	=	message_enqueue_time
								FROM	labViewStage.SQLMessageQueue
						)
					  , TIMEOUT 3000
						;

			IF	( @@ROWCOUNT = 0 )
			BEGIN
				ROLLBACK TRANSACTION ;
				BREAK ; 
			END

			  INSERT	labViewStage.SQLMessage
							( MessageProcessor, MessageType, MessageBody, MessageQueued )
			  SELECT	MessageProcessor	=	N'usp_Process_SQLSender'
					  , MessageType			=	@message_type_name
					  , MessageBody			=	@SQLStatement
					  , MessageQueued		=	@message_enqueue_time
						;

			IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
			BEGIN
				 END	CONVERSATION @conversation_handle ;
			END
			
			--	Process error message
			ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' )
			BEGIN
				--	shred error data from SB Error message
				--	log SB error
				--	end the conversation
				 DECLARE	@error			int
						  , @description	nvarchar(4000)
							;

					WITH	XMLNAMESPACES ( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
				  SELECT	@error			=	@message_body.value('(//ssb:Error/ssb:Code)[1]', 'int' )
						  , @description	=	@message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)' )
							;

				 EXECUTE	eLog.log_ProcessEventLog
								@pProcID	=	@@PROCID
							  , @pMessage	=	N'Received error code: %1 Description %2'
							  , @p1			=	@error
							  , @p2			=	@description
							;

				-- Now that we handled the error logging cleanup
					 END	CONVERSATION @conversation_handle ;
			END

			COMMIT TRANSACTION ;

		END
END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID = @@PROCID

	RETURN 55555 ;

END CATCH
