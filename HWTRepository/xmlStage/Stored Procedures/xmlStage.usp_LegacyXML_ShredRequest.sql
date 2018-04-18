CREATE PROCEDURE	[xmlStage].[usp_LegacyXML_ShredRequest]

/*
***********************************************************************************************************************************

    Procedure:  xmlStage.usp_LegacyXML_ShredRequest
    Abstract:   Activated by ShredderRequest Queue
				Process messages from Legacy XML ShredderRequest Queue

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
		  , @message_type_name		sysname 
  
		  , @HeaderID				int 
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
						 FROM	xmlStage.LegacyXML_ShredRequestQueue	
					)
				  , TIMEOUT 1000 
					; 		

				IF	( @@ROWCOUNT = 0 )
					BEGIN
						ROLLBACK TRANSACTION ; 
						BREAK ; 
					END 

				IF	( @message_type_name = N'//HWTRepository/LegacyXML/ShredResponse' )
					BEGIN
						  SELECT	@FileID			=	y.value('FileID[1]', 'uniqueidentifier' )
								  , @HeaderID		=	y.value('HeaderID[1]', 'int' )  
							FROM	@message_body.nodes('ShredResponse') AS x(y) 
									; 

						  UPDATE	xmlStage.ShreddedFile
							 SET	HeaderID 		=	@HeaderID
								  , ShredCompleted	=	CURRENT_TIMESTAMP
								  , CompletedBy		=	OBJECT_NAME( @@PROCID ) 
						   WHERE	FileID = @FileID 
									; 
									
							 END 	CONVERSATION @conversation_handle ; 	
					END  

				-- If end dialog message, end the dialog
				ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog' )
					BEGIN
					     END 	CONVERSATION @conversation_handle;
					END

				-- If error message, log and end conversation
				ELSE IF ( @message_type_name = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error' ) 
					BEGIN
					 DECLARE	@error INT 
					          , @description nvarchar(4000) 
								;

						-- Pull the error code and description from the doc
						WITH	XMLNAMESPACES 
									( 'http://schemas.microsoft.com/SQL/ServiceBroker/Error' AS ssb )
					  SELECT 	@error			=	@message_body.value('(//ssb:Error/ssb:Code)[1]', 'int')
							  , @description	= 	@message_body.value('(//ssb:Error/ssb:Description)[1]', 'nvarchar(4000)')
								;
				
						RAISERROR( N'Received error Code:%i Description:"%s"', 16, 1, @error, @description) WITH LOG ;

						-- Now that we handled the error logging cleanup
						 END 	CONVERSATION @conversation_handle ;
					END
				
				COMMIT TRANSACTION ; 
		END
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH