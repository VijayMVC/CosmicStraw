CREATE PROCEDURE labViewStage.usp_Process_SQLMessage
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

  DECLARE	@conversation_handle		uniqueidentifier
		  , @message_sequence_number	bigint
		  , @message_type_name			sysname
		  , @binary_message				varbinary(max)
		  , @message_body				xml
		  , @SQLStatement				nvarchar(max)
		  , @message_enqueue_time		datetime
		  , @errorCode					int
		  , @error_message				nvarchar(2048)
		  , @error_number				int
		  , @pErrorData					xml
			;


--	1)	Begin Loop to process all enqueued messages
WHILE	( 1 = 1 )
BEGIN TRY

--	2)	Initialize variables
  SELECT	@conversation_handle		=	NULL
		  , @message_sequence_number	=	NULL
		  , @message_type_name			=	NULL
		  , @binary_message				=	NULL
		  , @message_body				=	NULL
		  , @SQLStatement				=	NULL
		  , @error_number				=	NULL
			;

--	3)	RECEIVE messages from labViewStage.SQLMessageQueue
	BEGIN TRANSACTION ;

		 WAITFOR	(
					 RECEIVE	TOP( 1 )
								@conversation_handle		=	conversation_handle
							  , @message_sequence_number	=	message_sequence_number
							  , @binary_message				=	message_body
							  , @message_type_name			=	message_type_name
							  , @message_enqueue_time		=	message_enqueue_time
						FROM	labViewStage.SQLMessageQueue
					), TIMEOUT 3000
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
		IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
			BEGIN
				END CONVERSATION @conversation_handle ;
				COMMIT TRANSACTION ;
				CONTINUE ;
			END


		--	Message Type:	Service Broker error
		--	Req'd Action:	shred error data from SB Error message
		--					log error message
		--					record message in permanent storage
		--					end conversation
		IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' )
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
							;

				  INSERT	labViewStage.SQLMessage
								(
									MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
										, MessageBody, MessageQueued, ErrorCode, MessageProcessed
								)
				  SELECT	MessageProcessor		=	N'usp_Process_SQLMessage'
						  , MessageType				=	@message_type_name
						  , ConversationHandle		=	@conversation_handle
						  , MessageSequenceNumber	=	@message_sequence_number
						  , MessageBody				=	convert( nvarchar(max), @binary_message )
						  , MessageQueued			=	@message_enqueue_time
						  , ErrorCode				=	@error
						  , MessageProcessed		=	SYSDATETIME()
							;

				END	CONVERSATION @conversation_handle ;
				COMMIT TRANSACTION ;
				CONTINUE ;
			END


		--	Message Type:	Any other message type EXCEPT SQLMessage ( unexpected message type error )
		--	Req'd Action:	log error message
		--					record message in permanent storage
		--					end the conversation
		IF	( @message_type_name != N'//HWTRepository/LabVIEW/SQLMessage' )
			BEGIN
				 EXECUTE	eLog.log_ProcessEventLog
								@pProcID	=	@@PROCID
							  , @pMessage	=	N'Service Broker unexpected message type!  Message Type: %1'
							  , @p1			=	@message_type_name
							;

				  INSERT	labViewStage.SQLMessage
								(
									MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
										, MessageBody, MessageQueued, ErrorCode, MessageProcessed
								)
				  SELECT	MessageProcessor		=	N'usp_Process_SQLMessage'
						  , MessageType				=	@message_type_name
						  , ConversationHandle		=	@conversation_handle
						  , MessageSequenceNumber	=	@message_sequence_number
						  , MessageBody				=	convert( nvarchar(max), @binary_message )
						  , MessageQueued			=	@message_enqueue_time
						  , ErrorCode				=	55555
						  , MessageProcessed		=	SYSDATETIME()
							;

				END CONVERSATION @conversation_handle ;
				COMMIT TRANSACTION ;
				CONTINUE ;
			END

--	4)	Process SQLMessage message type

		--	Determine whether or not message has already been processed
		  SELECT	@error_number	=	ErrorCode
			FROM	labViewStage.SQLMessage WITH ( NOLOCK )
		   WHERE	ConversationHandle = @conversation_handle
						AND MessageSequenceNumber = @message_sequence_number
					;

		--	Message was either not found or , process message appropriately
		IF	( @error_number IS NULL )
			BEGIN TRY

				--	Determine whether this record has been previously deadlocked.
					--	if record has been previously processed, delay before reprocessing
				IF	EXISTS
						(
							  SELECT	1
								FROM	eLog.EventLog WITH ( NOLOCK )
										CROSS APPLY ErrorData.nodes( 'usp_Process_SQLMessage/message_data' ) AS e(xmldata)
							   WHERE	@conversation_handle = e.xmldata.value( 'conversation_handle[1]', 'uniqueidentifier' )
						)
					--	record has been previously deadlocked, delay processing
					BEGIN
						WAITFOR	DELAY '00:00:00:500' ;
					END


				  SELECT	@SQLStatement 	= 	CONVERT( nvarchar(max), @binary_message ) ;
				  
				  SELECT	@SQLStatement	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( @SQLStatement, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
				  
				 EXECUTE	( @SQLStatement ) ;

				 EXECUTE	hwt.usp_LoadRepositoryFromStage ;

			END TRY
			--	CATCH dynamic SQL failure from EXEC statement
			BEGIN CATCH
				--	ROLLBACK
				--	log the error ( set @pReraise = 0, we want only to log the error )
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
							  , @pError_Number	=	@error_number OUTPUT
							  , @pErrorData		=	@pErrorData
							;

				--	Write the poison message to SQLMessages table
				IF	( @error_number <> 1205 )
					  INSERT	labViewStage.SQLMessage
									(
										MessageProcessor, MessageType, ConversationHandle
											, MessageSequenceNumber, MessageBody, MessageQueued
											, ErrorCode, ErrorMessage, MessageProcessed
									)
					  SELECT	MessageProcessor		=	N'usp_Process_SQLMessage'
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

		--	Message had already been processed
		ELSE
			BEGIN
			--	clean up conversation and COMMIT
				END CONVERSATION @conversation_handle ;
				COMMIT TRANSACTION ;
				CONTINUE ;
			END

		--	Determine whether new messages processed correctly
			--	Record message in labViewStage.SQLMessage
			--	COMMIT
			--	end the conversation
		IF	( ISNULL( @error_number, 0 ) = 0 )
			BEGIN
				  INSERT	labViewStage.SQLMessage
								(
									MessageProcessor, MessageType, ConversationHandle
										, MessageSequenceNumber, MessageBody, MessageQueued
										, ErrorCode, ErrorMessage, MessageProcessed
								)
				  SELECT	MessageProcessor		=	N'usp_Process_SQLMessage'
						  , MessageType				=	@message_type_name
						  , ConversationHandle		=	@conversation_handle
						  , MessageSequenceNumber	=	@message_sequence_number
						  , MessageBody				=	N''
						  , MessageQueued			=	@message_enqueue_time
						  , ErrorCode				=	ISNULL( @error_number, 0 )
						  , ErrorMessage			=	@error_message
						  , MessageProcessed		=	SYSDATETIME()
							;

				END CONVERSATION @conversation_handle ;

				COMMIT TRANSACTION ;
			END

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID = @@PROCID

	RETURN 55555 ;

END CATCH
