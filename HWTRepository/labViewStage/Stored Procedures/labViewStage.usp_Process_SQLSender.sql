CREATE PROCEDURE labViewStage.usp_Process_SQLSender
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_Process_SQLSender
	Abstract:	SQL Sender Activator Queue

	Logic Summary
	-------------
	1)	Begin Loop to process all enqueued messages
	2)	RECEIVE messages from labViewStage.SQLSenderQueue
	3)	Process RECEIVEd message by message type
	4)	COMMIT transaction and iterate for next message


	Parameters
	----------

	Notes
	-----
	Derived from code originally appearing in: 
		Error and Transaction Handling in SQL Server
		Erland Sommarskog, Microsoft SQL Server MVP
		http://www.sommarskog.se/error_handling/Appendix3.html
		

	Revision
	--------
	carsoc3		2018-08-31		added messaging architecture for labViewStage data

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

  DECLARE	@conversation_handle		uniqueidentifier
		  , @message_sequence_number	bigint
		  , @message_type_name			sysname
		  , @binary_message				varbinary(max)
		  , @message_body				xml
		  , @message_enqueue_time		datetime
		  , @errorCode					int
		  , @error_message				nvarchar(2048)
		  , @error_number				int
			;
			

--	1)	Begin Loop to process all enqueued messages
WHILE	( 1 = 1 )
BEGIN TRY

	  SELECT 	@conversation_handle		=	NULL 
			  , @message_sequence_number	=	NULL 
			  , @message_type_name			=	NULL 
			  , @binary_message				=	NULL 
			  , @message_body				=	NULL 
			  , @error_number				=	NULL 
				;

--	2)	RECEIVE messages from labViewStage.SQLSenderQueue
	BEGIN TRANSACTION ;

		 WAITFOR	(
					 RECEIVE	TOP( 1 )
								@conversation_handle		=	conversation_handle
							  , @message_sequence_number	=	message_sequence_number
							  , @binary_message				=	message_body
							  , @message_type_name			=	message_type_name
							  , @message_enqueue_time		=	message_enqueue_time
						FROM	labViewStage.SQLSenderQueue
					), TIMEOUT 3000
					;

		--	no more messages, clean up and end
		--	COMMIT is required here to prevent transaction mismatch error 266
		IF	( @conversation_handle IS NULL )
		BEGIN
			COMMIT TRANSACTION ;
			BREAK ;
		END

--	3)	Process RECEIVEd message by message type
		--	end dialog message
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
		BEGIN
			--	clean up conversation
			END CONVERSATION @conversation_handle ;
		END


		--	Service Broker error message
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' )
		BEGIN
			--	shred error data from SB Error message
			 DECLARE	@error			int
					  , @description	nvarchar(4000)
							;

			  SELECT	@message_body = CONVERT( xml, @binary_message ) ;

				WITH	XMLNAMESPACES ( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
			  SELECT	@error			=	@message_body.value('(//ssb:Error/ssb:Code)[1]', 'int' )
					  , @description	=	@message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)' )
						;

			--	log error message
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Received error code: %1 Description %2'
						  , @p1			=	@error
						  , @p2			=	@description
						;

			--	record message in permanent storage
			  INSERT	labViewStage.SQLMessage
						(
							MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
								, MessageBody, MessageQueued, ErrorCode, MessageProcessed
						)
			  SELECT	MessageProcessor		=	N'usp_Process_SQLSender'
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber	=	@message_sequence_number
					  , MessageBody				=	convert( nvarchar(max), @binary_message )
					  , MessageQueued			=	@message_enqueue_time
					  , ErrorCode				=	@error
					  , MessageProcessed		=	SYSDATETIME()
						;

			--	end the conversation
			END CONVERSATION @conversation_handle ;
		END

		--	Any other message type here is an error
		ELSE
		BEGIN
			--	log error message
			EXECUTE eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Service Broker unexpected message type!  Message Type: %1'
						  , @p1			=	@message_type_name
						;

			--	record message in permanent storage
			  INSERT	labViewStage.SQLMessage
							(
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, MessageProcessed
							)
			  SELECT	MessageProcessor		=	N'usp_Process_SQLSender'
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber	=	@message_sequence_number
					  , MessageBody				=	convert( nvarchar(max), @binary_message )
					  , MessageQueued			=	@message_enqueue_time
					  , ErrorCode				=	55555
					  , MessageProcessed		=	SYSDATETIME()
						;

			--	end the conversation
			END CONVERSATION @conversation_handle ;
		END

--	4)	COMMIT transaction and iterate for next message
	COMMIT TRANSACTION ;

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID = @@PROCID

	RETURN 55555 ;

END CATCH
