CREATE PROCEDURE	xmlStage.usp_CompareXML_Response
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
	carsoc3		2018-02-01		alpha release

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

  SELECT	@inProcessTagID	=	TagID
	FROM	hwt.vw_AllTags
   WHERE	TagTypeName = N'Modifier'
			AND TagName = N'In-Progress'
			;

--	1)	Begin Loop to process all enqueued messages
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

--	3)	RECEIVE messages from xmlStage.CompareXML_RequestQueue
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

				  INSERT	xmlStage.SQLMessage
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
		IF	( @message_type_name != N'//HWTRepository/CompareXML/Request' )
			BEGIN
				 EXECUTE	eLog.log_ProcessEventLog
								@pProcID	=	@@PROCID
							  , @pMessage	=	N'Service Broker unexpected message type!  Message Type: %1'
							  , @p1			=	@message_type_name
							;

				  INSERT	xmlStage.SQLMessage
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


--	4)	Process Request message

		--	Determine whether or not message has already been processed
		  SELECT	@error_number	=	ErrorCode
			FROM	xmlStage.SQLMessage WITH ( NOLOCK )
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
									CROSS APPLY ErrorData.nodes( 'usp_CompareXML_Response/message_data' ) AS e(xmldata)
						   WHERE	@conversation_handle = e.xmldata.value( 'conversation_handle[1]', 'uniqueidentifier' )
					)
				--	record has been previously deadlocked, delay processing
				BEGIN
					WAITFOR	DELAY '00:00:00:500' ;
				END

			--	SELECT xml file data from file table 				
			  SELECT	@request_message_body	=	CONVERT( nvarchar(max), @binary_message ) ;

			  SELECT	@FileID					=	message.xmlData.value('FileID[1]', 'uniqueidentifier' )
				FROM	@request_message_body.nodes('CompareRequest') AS message(xmlData)
						;

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

			--	In-Progress tag from validated dataset
			  SELECT	@pHeaderIDStr	=	CONVERT( nvarchar(20), @pHeaderID ) ;

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

				--	Write the poison message to SQLMessage table
				IF	( @error_number <> 1205 )
					  INSERT	xmlStage.SQLMessage
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

		--	Message had already been processed
		ELSE
			BEGIN
			--	clean up conversation and COMMIT
				END CONVERSATION @conversation_handle ;
				COMMIT TRANSACTION ;
				CONTINUE ;
			END

		--	Determine whether new messages processed correctly
			--	Record message in xmlStage.SQLMessage
			--	Send response message to xmlStage.CompareXML_RequestQueue
			--	COMMIT
		IF	( ISNULL( @error_number, 0 ) = 0 )
			BEGIN
				  INSERT	xmlStage.SQLMessage
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
