CREATE PROCEDURE
	xmlStage.usp_ShredLegacyXML_Request

/*
***********************************************************************************************************************************

	Procedure:	xmlStage.usp_LegacyXML_ShredRequest
	Abstract:	Activated by Request Queue of Shred Legacy XML Service
				Process messages from ShredLegacyXML Request Queue

	Logic Summary
	-------------


	Parameters
	----------

	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;
/*
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

		  , @FileID						uniqueidentifier
		  , @pHeaderID					int
		  , @HeaderIDStr				nvarchar(20)
		  , @InProcessTagID				nvarchar(20)
		  , @VectorCountRetry			int
		  , @InputXML					xml( CONTENT xmlStage.LabViewXSD )
		  , @procedureName				sysname				=	N'usp_ShredLegacyXML_Request'
			;

--	1)	Iterate over xmlStage.ShredLegacyXML_RequestQueue
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


--	2)	Receive message from queue			
	BEGIN TRANSACTION ;

		 WAITFOR	(
					  RECEIVE	TOP( 1 )
								@conversation_handle	=	conversation_handle
							  , @message_body			=	message_body
							  , @message_type_name		=	message_type_name
						 FROM	xmlStage.ShredLegacyXML_RequestQueue
					), TIMEOUT 1000
					;

		--	no more messages, clean up and end
		--	COMMIT is required here to prevent transaction mismatch error 266				
		IF	( @@ROWCOUNT = 0 )
		BEGIN
			ROLLBACK TRANSACTION ;
			RETURN ;
		END

		
--	4)	Process messages that are non-contract message types
		--	Message Type:	end dialog
		--	Req'd Action:	end conversation
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
		BEGIN
			END CONVERSATION @conversation_handle ;
			CONTINUE ;
		END


		--	Message Type:	Service Broker error
		--	Req'd Action:	shred error data from SB Error message
		--					log error message
		--					record message in permanent storage
		--					end conversation
		ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' )
		BEGIN
		 DECLARE	@error INT
				  , @description nvarchar(4000)
					;

			-- Pull the error code and description from the doc
			WITH	XMLNAMESPACES
						( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
		  SELECT	@error			=	@message_body.value('(//ssb:Error/ssb:Code)[1]', 'int')
				  , @description	=	@message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)')
					;

			RAISERROR( N'Received error Code:%i Description:"%s"', 16, 1, @error, @description) WITH LOG ;

			-- Now that we handled the error logging cleanup
			 END	CONVERSATION @conversation_handle ;
		END

			COMMIT TRANSACTION ;
			
			
			IF	( @message_type_name = N'//HWTRepository/ShredLegacyXML/Response' )
			BEGIN
				  SELECT	@FileID			=	y.value('FileID[1]', 'uniqueidentifier' )
						  , @HeaderID		=	y.value('HeaderID[1]', 'int' )
					FROM	@message_body.nodes('ShredResponse') AS x(y)
							;

				  UPDATE	xmlStage.ShreddedFile
					 SET	HeaderID		=	@HeaderID
						  , ShredCompleted	=	CURRENT_TIMESTAMP
						  , CompletedBy		=	OBJECT_NAME( @@PROCID )
				   WHERE	FileID = @FileID
							;

					 END	CONVERSATION @conversation_handle ;
			END


	END
END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ;

	RETURN 55555 ;

END CATCH
*/
RETURN 
