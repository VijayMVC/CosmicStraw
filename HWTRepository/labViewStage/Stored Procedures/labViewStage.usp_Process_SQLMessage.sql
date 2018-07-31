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
			;

			
--	1)	Begin Loop to process all enqueued messages
WHILE	( 1 = 1 )
BEGIN TRY 
	
--	2)	Initialize variables
	  SELECT 	@conversation_handle		=	NULL 
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
			BREAK ; 
		END

--	4)	Process RECEIVEd message by message type
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
						  , @pMessage	=	N'Service Broker error!  Error code: %1  Description: %2'
						  , @p1			=	@error
						  , @p2			=	@description
						;
							
			--	record message in permanent storage							
			  INSERT 	labViewStage.SQLMessage 
							( 
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, MessageProcessed
							) 
			  SELECT 	MessageProcessor		=	N'usp_Process_SQLMessage'
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber   =	@message_sequence_number
					  , MessageBody             =	convert( nvarchar(max), @binary_message )
					  , MessageQueued           =	@message_enqueue_time
					  , ErrorCode               =	@error
					  , MessageProcessed		=	SYSDATETIME()
						; 
						  
			--	end the conversation
			END	CONVERSATION @conversation_handle ;
		END 
			
		--	Any other message type beside SQLMessage is an error			
		ELSE IF	( @message_type_name != N'//HWTRepository/LabVIEW/SQLMessage' )
		BEGIN 
			--	log error message
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Service Broker unexpected message type!  Message Type: %1'
						  , @p1			=	@message_type_name
						;
							
			--	record message in permanent storage
			  INSERT 	labViewStage.SQLMessage 
							( 
								MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
									, MessageBody, MessageQueued, ErrorCode, MessageProcessed
							) 
			  SELECT 	MessageProcessor		=	N'usp_Process_SQLMessage'
					  , MessageType				=	@message_type_name
					  , ConversationHandle		=	@conversation_handle
					  , MessageSequenceNumber   =	@message_sequence_number
					  , MessageBody             =	convert( nvarchar(max), @binary_message )
					  , MessageQueued           =	@message_enqueue_time
					  , ErrorCode               =	55555
					  , MessageProcessed		=	SYSDATETIME()
						; 
						
			--	end the conversation
			END CONVERSATION @conversation_handle ; 
		END
		
--	5)	Process SQLMessage 
		ELSE 
		BEGIN 
			--	check permanent storage to determine whether message exists
			  SELECT	@error_number 	=	ErrorCode 
				FROM 	labViewStage.SQLMessage 
			   WHERE	ConversationHandle = @conversation_handle
							AND MessageSequenceNumber = @message_sequence_number
						; 
						
			--	NULL means this message has not been processed 
			IF	( @error_number IS NULL ) 
			BEGIN TRY 
		
				--	EXEC SQL formatted in SQLMessage message body
				  SELECT	@SQLStatement	=	CONVERT( nvarchar(max), @binary_message ) ; 
					EXEC	( @SQLStatement ) ;
						
				
					--	Check for any SQL return except deadlock 
						--	1205 is rolled back and message goes back to queue
						--	any other messages needs to be processed here
					IF	( ISNULL( @error_number, 0 ) <> 1205 ) 
							--	record message in permanent storage
								--	SQL errors other than 1205 are poison messages
								--	poison messages need to be recorded so they are not reprocessed 
						  INSERT 	labViewStage.SQLMessage 
										( 
											MessageProcessor, MessageType, ConversationHandle, MessageSequenceNumber
												, MessageBody, MessageQueued, ErrorCode, MessageProcessed
										) 
						  SELECT 	MessageProcessor		=	N'usp_Process_SQLMessage'
								  , MessageType				=	@message_type_name
								  , ConversationHandle		=	@conversation_handle
								  , MessageSequenceNumber   =	@message_sequence_number
								  , MessageBody             =	convert( nvarchar(max), @binary_message )
								  , MessageQueued           =	@message_enqueue_time
								  , ErrorCode               =	ISNULL( @error_number, 0 ) 
								  , MessageProcessed		=	SYSDATETIME()
									; 
			END TRY 
			BEGIN CATCH 
				--	See Notes for detailed discussion of process
				--	CATCH is invoked when dynamic SQL from EXEC statement fails
				-- 	ROLLBACK transaction
				IF	( @@trancount > 0 ) ROLLBACK TRANSACTION ; 

				--	log the error 
					--	@pReraise is set to 0, so as only record the error
				EXECUTE 	eLog.log_CatchProcessing
								@pProcID 		= 	@@PROCID
							  , @pReraise		=	0
							  , @pError_Number	=	@error_number OUTPUT 
							; 
				-- 	control passes here back to TRY block for further processing
			END CATCH 
			
			--	Determine whether transaction was rolled back 
			IF	( @@trancount > 0 ) 
			BEGIN 
			--	clean up conversation and COMMIT 
				END CONVERSATION @conversation_handle ;
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
