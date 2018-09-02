CREATE PROCEDURE
	labViewStage.usp_Process_SQLMessage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_Process_SQLMessage
	Abstract:	executes SQL statements sent via SQL Message

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

  DECLARE	@conversation_handle			uniqueidentifier
		  , @conversation_group_id			uniqueidentifier
		  , @message_sequence_number		bigint
		  , @message_type_name				sysname
		  , @binary_message					varbinary(max)
		  , @message_body					xml
		  , @SQLStatement					nvarchar(max)
		  , @message_enqueue_time			datetime
		  , @errorCode						int
		  , @error_message					nvarchar(2048)
		  , @error_number					int
		  , @pErrorData						xml
		  , @pLogID							int
		  , @procedureName					sysname				=	N'usp_Process_SQLMessage'
		  , @setXACT_ABORT					nvarchar(50)		=	N'SET XACT_ABORT, NOCOUNT ON ;'
		;

  DECLARE	@batch_message_limit			int					=	5
		  , @batch_message_count			int					=	0
		  , @batch_conversation_group_id	uniqueidentifier	=	NULL
			;



--	1)	Begin Loop to process all enqueued messages
WHILE	( 1 = 1 )
BEGIN TRY

IF	( @batch_message_count = 0 ) BEGIN TRANSACTION ;

--	2)	Initialize message variables
  SELECT	@conversation_handle		=	NULL
		  , @conversation_group_id		=	NULL
		  , @message_sequence_number	=	NULL
		  , @message_type_name			=	NULL
		  , @binary_message				=	NULL
		  , @message_body				=	NULL
		  , @SQLStatement				=	NULL
		  , @error_number				=	NULL
		  , @error_message				=	NULL
			;

--	3)	RECEIVE messages from labViewStage.SQLMessageQueue

		 WAITFOR	(
					 RECEIVE	TOP( 1 )
								@conversation_handle		=	conversation_handle
							  , @conversation_group_id		=	conversation_group_id
							  , @message_sequence_number	=	message_sequence_number
							  , @binary_message				=	message_body
							  , @message_type_name			=	message_type_name
							  , @message_enqueue_time		=	message_enqueue_time
						FROM	labViewStage.SQLMessageQueue
					), TIMEOUT 1000
					;

		--	no more messages, clean up and end
		--	COMMIT is required here to prevent transaction mismatch error 266
		IF	( @conversation_handle IS NULL )
		BEGIN
			COMMIT TRANSACTION ;
			RETURN ;
		END

--	4)	Process messages that are not message type SQLMessage
		--	Message Type:	end dialog
		--	Req'd Action:	end conversation
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
		BEGIN
			BREAK ;
		END


		--	Message Type:	Service Broker error
		--	Req'd Action:	shred error data from SB Error message
		--					log error message
		--					record message in permanent storage
		--					end conversation
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' )
		BEGIN
			 DECLARE	@error			int
					  , @description	nvarchar(4000)
						;

			  SELECT	@message_body = CONVERT( xml, @binary_message ) ;

				WITH	XMLNAMESPACES ( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
			  SELECT	@error			=	@message_body.value('(//ssb:Error/ssb:Code)[1]', 'int' )
					  , @description	=	@message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)' )
						;

			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Service Broker error!	 Error code: %1	 Description: %2'
						  , @p1			=	@error
						  , @p2			=	@description
						  , @pLogID		=	@pLogID			OUTPUT
						;

			  INSERT	eLog.ServiceBrokerMessage
							(
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, ErrorMessage, MessageProcessed
							)
			  SELECT	MessageProcessor		=	@ProcedureName
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber	=	@message_sequence_number
					  , MessageBody				=	convert( nvarchar(max), @binary_message )
					  , MessageQueued			=	@message_enqueue_time
					  , ErrorCode				=	@error
					  , ErrorMessage			=	N'EventLog ID: ' + convert( nvarchar(20), @pLogID )
					  , MessageProcessed		=	SYSDATETIME()
						;

			BREAK ;
		END


		--	Message Type:	Any other message type EXCEPT SQLMessage ( unexpected message type error )
		--	Req'd Action:	log error message
		--					record message in permanent storage
		--					end the conversation
		ELSE IF	( @message_type_name != N'//HWTRepository/LabVIEW/SQLMessage' )
		BEGIN
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Service Broker unexpected message type!  Message Type: %1'
						  , @p1			=	@message_type_name
						  , @pLogID		=	@pLogID				OUTPUT
						;

			  INSERT	eLog.ServiceBrokerMessage
							(
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, ErrorMessage, MessageProcessed
							)
			  SELECT	MessageProcessor		=	@ProcedureName
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber	=	@message_sequence_number
					  , MessageBody				=	convert( nvarchar(max), @binary_message )
					  , MessageQueued			=	@message_enqueue_time
					  , ErrorCode				=	@error
					  , ErrorMessage			=	N'EventLog ID: ' + convert( nvarchar(20), @pLogID )
					  , MessageProcessed		=	SYSDATETIME()
						;

			BREAK ;
		END

--	4)	Process SQLMessage message type
		--	Req'd Action:	Determine whether or not message has already been processed
		--					process message appropriately depending on whether found or not
		--					end the conversation

		--	Check for poison message that has been previously processed and error was thrown
		--	Use table hint WITH ( NOLOCK )
		--		This gives visibility to a poison message that may not yet be committed in another queue readers
		--		Prevents this proc from reprocessing a poison message

		ELSE IF	EXISTS	(
						SELECT	1
						FROM	eLog.ServiceBrokerMessage WITH ( NOLOCK )
						WHERE	MessageProcessor = @ProcedureName
									AND ConversationHandle = @conversation_handle
									AND MessageSequenceNumber = @message_sequence_number
					)
		BEGIN
			BREAK
		END

		ELSE
		BEGIN
			BEGIN TRY
				--	Load SQLStatment message payload
				--	Un-escape any XML characters embedded in message payload
				--	Execute SQL Message

				  SELECT	@SQLStatement	=	CONVERT( nvarchar(max), @binary_message ) ;
				  SELECT	@SQLStatement	=	@setXACT_ABORT + REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( @SQLStatement, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
				 EXECUTE	( @SQLStatement ) ;

				--	Load HWT Repository with data after successful execution of SQL
				 EXECUTE	hwt.usp_LoadRepositoryFromStage ;

			END TRY
			BEGIN CATCH
				--	delay processing for 50ms if the error is a deadlock
				--	ROLLBACK
				--	execute error handler
				--	write poison message ( exclude 1205 errors )
				--		note that 1205 is a deadlock that can be reprocessed

				IF	( ERROR_NUMBER() = 1205 ) WAITFOR DELAY '00:00:00.050' ;

				IF	( @@trancount > 0 ) ROLLBACK TRANSACTION ;

				  SELECT	@pErrorData =	(
											  SELECT	(
														  SELECT	conversation_handle	=	@conversation_handle
																	FOR XML PATH( 'message_data' ), TYPE, ELEMENTS XSINIL
														)
														FOR XML PATH( 'usp_Process_SQLMessage' ), TYPE
											)
							;

				 EXECUTE	eLog.log_CatchProcessing
								@pProcID		=	@@PROCID
							  , @pReraise		=	0
							  , @pError_Number	=	@error_number	OUTPUT
							  , @pMessage_aug	=	@error_message	OUTPUT
							  , @pErrorData		=	@pErrorData
							;

				IF	( @error_number <> 1205 )
				  INSERT	eLog.ServiceBrokerMessage
								(
									MessageProcessor, MessageType, ConversationHandle
										, MessageSequenceNumber, MessageBody, MessageQueued
										, ErrorCode, ErrorMessage, MessageProcessed
								)
				  SELECT	MessageProcessor		=	@ProcedureName
						  , MessageType				=	@message_type_name
						  , ConversationHandle		=	@conversation_handle
						  , MessageSequenceNumber	=	@message_sequence_number
						  , MessageBody				=	convert( nvarchar(max), @binary_message )
						  , MessageQueued			=	@message_enqueue_time
						  , ErrorCode				=	ISNULL( @error_number, 0 )
						  , ErrorMessage			=	@error_message
						  , MessageProcessed		=	SYSDATETIME()
							;
			END CATCH
			IF	( @@TRANCOUNT > 0 )
			  INSERT	eLog.ServiceBrokerMessage
							(
								MessageProcessor, MessageType, ConversationHandle
									, MessageSequenceNumber, MessageQueued, ErrorCode
									, ErrorMessage, MessageProcessed
							)
			  SELECT	MessageProcessor		=	@ProcedureName
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber	=	@message_sequence_number
					  , MessageQueued			=	@message_enqueue_time
					  , ErrorCode				=	ISNULL( @error_number, 0 )
					  , ErrorMessage			=	@error_message
					  , MessageProcessed		=	SYSDATETIME()
						;
		END

	IF	( @@TRANCOUNT > 0 )
	BEGIN

		END CONVERSATION @conversation_handle ;
		SELECT	@batch_message_count += 1 ;

		IF	( @batch_message_count	=	@batch_message_limit )
		BEGIN
			SELECT	@batch_message_count = 0 ;
			COMMIT TRANSACTION ;
		END
	END

END TRY
BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID = @@PROCID

	RETURN 55555 ;

END CATCH
