CREATE PROCEDURE	[xmlStage].[usp_LegacyXML_ShredResponse]

/*
***********************************************************************************************************************************

    Procedure:  xmlStage.usp_LegacyXML_ShredResponse
    Abstract:   shreds legacy XML data into labViewStage tables

    Logic Summary
    -------------


    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ; 

BEGIN TRY 

  DECLARE	@conversation_handle	uniqueidentifier
		  , @message_body			xml	
		  , @response_message_body	xml
		  , @message_type_name		sysname 
		  , @error_message			nvarchar(2048) 
		  , @error_number			int 
			; 
		  
  DECLARE 	@HeaderID				int 
		  , @FileID					uniqueidentifier 
			; 
		  
	
	WHILE	( 1 = 1 )
		BEGIN 

			BEGIN TRANSACTION ; 

				WAITFOR						 
					( 
					  RECEIVE	TOP( 1 )
								@conversation_handle	=	conversation_handle
							  , @message_body			=	message_body
							  , @message_type_name		=	message_type_name
						 FROM	xmlStage.LegacyXML_ShredResponseQueue	
					), TIMEOUT 1000 
					; 		

				IF	( @@ROWCOUNT = 0 ) 
					BEGIN
						ROLLBACK TRANSACTION ; 
						RETURN ; 
					END 

				--	Process Shred Request message 
				IF	( @message_type_name = N'//HWTRepository/LegacyXML/ShredRequest' )
					BEGIN 
					--	shred header and file IDs from inbound ShredRequest message 
					--	execute XML Shredder stored procedure
					--	format and send ShredResponse message 
					
						  SELECT	@FileID			=	msg.value('FileID[1]', 'uniqueidentifier' ) 
							FROM 	@message_body.nodes( 'ShredRequest' ) AS x( msg ) 
									; 
						
						 EXECUTE	xmlStage.usp_ShredLegacyXML 
										@pFileID	=	@FileID 
									  , @pHeaderID	=	@HeaderID	OUTPUT 
									; 
						
						  SELECT	@error_message	=	ERROR_MESSAGE()
								  , @error_number	=	ERROR_NUMBER() 
									;
						
						  SELECT	@response_message_body	=	( 
																  SELECT	HeaderID		=	@HeaderID 
																		  , FileID			=	@FileID
																			FOR XML PATH( 'ShredResponse' ) 
																) 
									; 
																
						 SEND ON	CONVERSATION @conversation_handle
									MESSAGE TYPE [//HWTRepository/LegacyXML/ShredResponse] 
										( @response_message_body ) 
									; 
					
					END
				
				-- 	Process end dialog message
				ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
					BEGIN
							 END 	CONVERSATION @conversation_handle ;
					END

				
				-- 	Process error message 
				ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' ) 
				BEGIN
					--	shred error data from SB Error message 
					--	log SB error 
					--	end the conversation 
						 DECLARE 	@error 			int 
								  , @description 	nvarchar(4000) 
									;

							WITH 	XMLNAMESPACES ( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
						  SELECT	@error			=	@message_body.value('(//ssb:Error/ssb:Code)[1]', 'int' )
								  ,	@description 	=	@message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)' ) 
									;
			
						 EXECUTE	eLog.log_ProcessEventLog 
						 				@pProcID	=	@@PROCID
									  , @pMessage	=	N'Received error code: %1 Description %2' 
									  , @p1			=	@error 
									  , @p2			=	@description
									;						 
									
					-- Now that we handled the error logging cleanup
							 END 	CONVERSATION @conversation_handle ;
				END
				
				COMMIT TRANSACTION ; 
				
		END
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing 
			@pProcID = @@PROCID
	 
	RETURN 55555 ; 

END CATCH