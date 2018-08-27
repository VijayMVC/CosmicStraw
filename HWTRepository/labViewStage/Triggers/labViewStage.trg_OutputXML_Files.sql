  CREATE	TRIGGER	labViewStage.trg_OutputXML_Files
	  ON	labViewStage.OutputXML_Files
	 FOR	INSERT
/*
***********************************************************************************************************************************

	 Trigger:	labViewStage.trg_OutputXML_Files
	Abstract:	sends message to CompareXML Services to validate input data 

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

BEGIN TRY	

 DECLARE	@insertedFiles AS TABLE( FileID uniqueidentifier ) ; 

 DECLARE	@conversation_handle	uniqueidentifier 
		  , @CompareRequestMessage	xml
		  , @FileID					uniqueidentifier 
			; 
			
--	1)	INSERT	FileID(s) from file table into temp storage			
		--	ignores files that may already exist in the system

  INSERT	@insertedFiles 
  SELECT 	FileID 			=	i.stream_id
	FROM 	inserted AS i 
   WHERE	NOT EXISTS ( SELECT 1 FROM xmlStage.InputXMLFile AS x WHERE x.FileID = i.stream_id ) 
			; 

--	2)	Iterate over processed files, sending CompareRequest message for each file 
   WHILE	EXISTS( SELECT 1 FROM @insertedFiles ) 
				BEGIN 
				
					  SELECT	TOP 1
								@FileID		=	FileID 
						FROM	@insertedFiles 
					ORDER BY	FileID
								; 
					
					  SELECT	@CompareRequestMessage	=	( SELECT FileID	= @FileID FOR XML PATH( 'CompareRequest' ) ) ; 
						  
					   BEGIN	DIALOG @conversation_handle
								FROM SERVICE	[//HWTRepository/CompareXML/RequestService]
								TO SERVICE		N'//HWTRepository/CompareXML/ResponseService'
								ON CONTRACT		[//HWTRepository/CompareXML/CompareXMLContract]
								WITH ENCRYPTION = OFF ; 

					 SEND ON	CONVERSATION @conversation_handle
								MESSAGE TYPE [//HWTRepository/CompareXML/Request]
								( @CompareRequestMessage ) ; 

					  DELETE	@insertedFiles
					   WHERE	FileID = @FileID  
								;
				END 

END TRY
BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	stream_id, name, path = file_stream.GetFileNamespacePath(1 , 0)
															, creation_time, last_write_time, last_access_time
												FROM	inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'trg_OutputXML_Files' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
