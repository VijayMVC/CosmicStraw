CREATE TRIGGER		xmlStage.trg_LegacyXML_Files
			ON		xmlStage.LegacyXML_Files
		   FOR 		INSERT

-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON 
;

BEGIN TRY	
	 DECLARE	@insertedFiles AS TABLE( FileID uniqueidentifier ) 
; 
	 DECLARE	@conversation_handle	uniqueidentifier 
			  , @ShredRequestMessage	xml
			  , @FileID					uniqueidentifier 
; 
	  INSERT	xmlStage.ShreddedFile( FileID, ShredRequested, RequestedBy ) 
	  OUTPUT	inserted.FileID INTO @insertedFiles( FileID ) 
	  SELECT 	FileID 			=	i.stream_id
			  , ShredRequested	=	CURRENT_TIMESTAMP
			  , RequestedBy 	=	OBJECT_NAME( @@PROCID )  
		FROM 	inserted AS i 
	   WHERE	NOT EXISTS ( SELECT 1 FROM xmlStage.ShreddedFile AS x WHERE x.FileID = i.stream_id AND x.HeaderID IS NOT NULL ) 
; 

	   WHILE	EXISTS( SELECT 1 FROM @insertedFiles ) 
			BEGIN 
				  SELECT	TOP 1
							@FileID		=	FileID 
					FROM	@insertedFiles 
				ORDER BY	FileID
; 
				  SELECT	@ShredRequestMessage	=	( 
														  SELECT	FileID		=	@FileID
																	FOR XML PATH( 'ShredRequest' ), TYPE 
														) 
; 
				   BEGIN	DIALOG @conversation_handle
							FROM SERVICE	[//HWTRepository/LegacyXML/ShredRequestService]
							TO SERVICE		N'//HWTRepository/LegacyXML/ShredResponseService'
							ON CONTRACT		[//HWTRepository/LegacyXML/ShredContract]
							WITH ENCRYPTION = OFF 
; 
				 SEND ON	CONVERSATION @conversation_handle
							MESSAGE TYPE [//HWTRepository/LegacyXML/ShredRequest]
							( @ShredRequestMessage ) 
; 
				  DELETE	@insertedFiles
				   WHERE	FileID = @FileID  
;
		   END 
END TRY
BEGIN CATCH
	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION 
; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID 
; 
END CATCH
