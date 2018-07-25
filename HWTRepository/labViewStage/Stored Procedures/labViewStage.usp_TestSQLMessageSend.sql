CREATE 	PROCEDURE labViewStage.usp_TestSQLMessageSend
/*

	Test procedure for sending SQL statements to the //HWTRepository/LabVIEW/SQLContract Service Broker architecture

*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY	

	 DECLARE	@conversation_handle	uniqueidentifier 
			  , @SQLMessage				nvarchar(max) 
			  , @queuing_order			int
				; 
			  
			  
	  SELECT 	queuing_order 
			  , casted_message_body	
		INTO 	#SQLMessages 
		FROM 	master..TestMessages 
				; 
				

	WHILE EXISTS( SELECT 1 FROM #SQLMessages ) 
	BEGIN 
	
	
		  SELECT	TOP 1
					@SQLMessage		=	casted_message_body
				  , @queuing_order	=	queuing_order
			FROM	#SQLMessages 
		ORDER BY	queuing_order
					; 
					
		BEGIN TRANSACTION ; 
	
			   BEGIN	DIALOG 			@conversation_handle
				FROM    SERVICE			[//HWTRepository/LabVIEW/SQLSender]      
				  TO    SERVICE			'//HWTRepository/LabVIEW/SQLTarget'      
				  ON    CONTRACT		[//HWTRepository/LabVIEW/SQLContract]    
				WITH    ENCRYPTION	=	OFF                                       
						;                                                      


				SEND    ON CONVERSATION @conversation_handle 
						MESSAGE TYPE [//HWTRepository/LabVIEW/SQLMessage]
							( @SQLMessage )
						;

		COMMIT ;

		  DELETE	#SQLMessages 
		   WHERE	queuing_order = @queuing_order
					;

	END 
					  
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	
END CATCH
