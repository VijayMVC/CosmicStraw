CREATE PROCEDURE
	xmlStage.usp_CompareXML_Response
/*
***********************************************************************************************************************************

	Procedure:	xmlStage.usp_CompareXML_Response
	Abstract:	Activated by Response Queue of Compare XML Service
				Process Request message from Response Queue of Compare XML Service

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

  DECLARE	@conversation_handle		uniqueidentifier
		  , @message_sequence_number	bigint
		  , @message_type_name			sysname
		  , @binary_message				varbinary(max)
		  , @request_message_body		xml
		  , @response_message_body		xml
		  , @message_enqueue_time		datetime
		  , @errorCode					int
		  , @error_message				nvarchar(2048)
		  , @error_number				int
		  , @pErrorData					xml

		  , @fileID						uniqueidentifier
		  , @fileName					nvarchar(255)
		  , @pHeaderID					int
		  , @pHeaderIDStr				nvarchar(20)
		  , @pInputXML					xml( CONTENT xmlStage.LabViewXSD )

		  , @inProcessTagID				nvarchar(20)
		  , @procedureName				sysname				=	N'usp_CompareXML_Response'
			;

  SELECT	@inProcessTagID	=	CONVERT( nvarchar(20), TagID )
	FROM	hwt.vw_AllTags
   WHERE	TagTypeName = N'Modifier'
			AND TagName = N'In-Progress'
			;

--	1)	Iterate over xmlStage.CompareXML_ResponseQueue
WHILE	( 1 = 1 )
BEGIN TRY


--	2)	Initialize variables
  SELECT	@conversation_handle		=	NULL
		  , @message_sequence_number	=	NULL
		  , @message_type_name			=	NULL
		  , @binary_message				=	NULL
		  , @request_message_body		=	NULL
		  , @response_message_body		=	NULL
		  , @error_number				=	NULL
			;

			
--	3)	RECEIVE message from queue
	BEGIN TRANSACTION ;

		 WAITFOR	(
					 RECEIVE	TOP( 1 )
								@conversation_handle		=	conversation_handle
							  , @message_sequence_number	=	message_sequence_number
							  , @binary_message				=	message_body
							  , @message_type_name			=	message_type_name
							  , @message_enqueue_time		=	message_enqueue_time
						FROM	xmlStage.CompareXML_ResponseQueue
					), TIMEOUT 3000
					;

		--	no more messages, clean up and end
		--	COMMIT is required here to prevent transaction mismatch error 266
		IF	( @conversation_handle IS NULL )
		BEGIN
			COMMIT TRANSACTION ;
			RETURN ;
		END

--	4)	Process messages that are non-contract message types
		--	Message Type:	end dialog
		--	Req'd Action:	end conversation
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
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
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' )
		BEGIN
			 DECLARE	@error			int
					  , @description	nvarchar(4000)
						;

			  SELECT	@request_message_body = CONVERT( xml, @binary_message ) ;

				WITH	XMLNAMESPACES ( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
			  SELECT	@error			=	@request_message_body.value('(//ssb:Error/ssb:Code)[1]', 'int' )
					  , @description	=	@request_message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)' )
						;

			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Service Broker error!	 Error code: %1	 Description: %2'
						  , @p1			=	@error
						  , @p2			=	@description
						;

			  INSERT	eLog.ServiceBrokerMessage
							(
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, MessageProcessed
							)
			  SELECT	MessageProcessor		=	@ProcedureName
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

		--	Message Type:	Any other message type EXCEPT Request ( unexpected message type error )
		--	Req'd Action:	log error message
		--					record message in permanent storage
		--					end the conversation
		ELSE IF	( @message_type_name != N'//HWTRepository/CompareXML/Request' )
		BEGIN
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Service Broker unexpected message type!  Message Type: %1'
						  , @p1			=	@message_type_name
						;

			  INSERT	eLog.ServiceBrokerMessage
							(
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, MessageProcessed
							)
			  SELECT	MessageProcessor		=	@ProcedureName
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

--	5)	Process Request Message
		--	Req'd Action:	Determine whether or not message has already been processed
		--					process message appropriately depending on whether found or not
		--					end the conversation

		--	Check for poison message that has been previously processed and error was thrown
		ELSE IF	EXISTS	(
						SELECT	1
						FROM	eLog.ServiceBrokerMessage WITH ( NOLOCK )
						WHERE	ConversationHandle = @conversation_handle
									AND MessageSequenceNumber = @message_sequence_number
					)
		BEGIN
			--	clean up conversation and COMMIT
			END CONVERSATION @conversation_handle ;
			COMMIT TRANSACTION ;
			CONTINUE ;
		END

		--	Message has not been processed successfully, but it may have been deadlocked
		ELSE IF	EXISTS
				(
					SELECT	1
					FROM	eLog.EventLog WITH ( NOLOCK )
							CROSS APPLY ErrorData.nodes( 'usp_CompareXML_Response/message_data' ) AS e(xmldata)
					WHERE	@conversation_handle = e.xmldata.value( 'conversation_handle[1]', 'uniqueidentifier' )
				)
		--	if error exists, current message is being re-processed because of deadlock, delay processing
		BEGIN
			WAITFOR	DELAY '00:00:00:500' ;
		END

		--	Message was not found, process message
		ELSE
		BEGIN TRY
			--	Get fileID from incoming message
			  SELECT	@request_message_body	=	CONVERT( nvarchar(max), @binary_message ) ;

			  SELECT	@FileID					=	message.xmlData.value('FileID[1]', 'uniqueidentifier' )
				FROM	@request_message_body.nodes('CompareRequest') AS message(xmlData)
								;

			--	Get XML data to be compared from FileTable
			  SELECT	@FileName	=	[name]
					  , @pInputXML	=	CONVERT( xml, file_stream )
				FROM	labViewStage.OutputXML_Files
			   WHERE	stream_id = @FileID
						;

			--	shred xml file data into xmlStage schema
			 EXECUTE	xmlStage.usp_ShredXMLData
							@pInputXML	=	@pInputXML
						  , @pHeaderID	=	@pHeaderID OUTPUT
						;

			--	compare shredded data to existing labViewStage data
			 EXECUTE	xmlStage.usp_CompareStageData
							@pHeaderID	=	@pHeaderID
						;

			--	after shred and compare, remove In-Progress tag from dataset
			  SELECT	@pHeaderIDStr	=	CONVERT( nvarchar(20), @pHeaderID )

			 EXECUTE	hwt.usp_RemoveTagsFromDatasets
							@pUserID	=	@ProcedureName
						  , @pHeaderID	=	@pHeaderIDStr
						  , @pTagID		=	@inProcessTagID
						;

			--	record successful validation of xml file
			  INSERT	xmlStage.InputXMLFile
							( FileID, FileName, FilePath, HeaderID, FileShredded )
			  SELECT	FileID			=	f.stream_id
					  , FileName		=	f.name
					  , FilePath		=	f.file_stream.GetFileNamespacePath(1, 0)
					  , HeaderID		=	x.ID
					  , FileShredded	=	SYSDATETIME()
				FROM	labViewStage.OutputXML_Files AS f
						INNER JOIN	xmlStage.header AS x
								ON	x.ResultFile = f.name
			   WHERE	f.stream_id = @FileID
						;

		END TRY

		--	CATCH errors from the executed SQL
		BEGIN CATCH
			--	ROLLBACK
			--	log the error ( set @pReraise = 0, we want only to log the error )
			IF	( @@trancount > 0 ) ROLLBACK TRANSACTION ;

			  SELECT	@pErrorData =	(
										  SELECT	(
													  SELECT	conversation_handle	=	@conversation_handle
																FOR XML PATH( 'message_data' ), TYPE, ELEMENTS XSINIL
													)
													FOR XML PATH( 'usp_CompareXML_Response' ), TYPE
										)
						;

			 EXECUTE	eLog.log_CatchProcessing
							@pProcID		=	@@PROCID
						  , @pReraise		=	0
						  , @pError_Number	=	@error_number OUTPUT
						  , @pErrorData		=	@pErrorData
						;

			--	IF the error was not a deadlock, write the poison message to SQLMessage table
			--	This prevents further processing of the message
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

		--	If message processed correctly, finish processing here
			--	Record message in xmlStage.SQLMessage
			--	Send response message to xmlStage.CompareXML_RequestQueue
			--	COMMIT
		IF 	ISNULL( @error_number, 0 ) = 0 
		BEGIN 
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

			  SELECT	@response_message_body	=	(
													  SELECT	HeaderID	=	@pHeaderID
																FOR XML PATH( 'CompareResponse' )
													)
						;

				SEND	ON	CONVERSATION @conversation_handle
							MESSAGE TYPE [//HWTRepository/CompareXML/Response]
								( @response_message_body )
						;

			COMMIT TRANSACTION ;
		END
			
END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID = @@PROCID

	RETURN 55555 ;

END CATCH
