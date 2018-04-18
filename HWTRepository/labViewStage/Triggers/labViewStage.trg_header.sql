CREATE TRIGGER	labViewStage.trg_header
			ON 	labViewStage.header
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

     DECLARE 	@CurrentHeaderID int ; 
	
	  SELECT 	@CurrentHeaderID = ISNULL( MAX( HeaderID ), 0 ) FROM hwt.Header ; 

--	Load trigger data into temp storage
      SELECT 	*
		INTO 	#inserted 
		FROM 	inserted 
				;
	
	  UPDATE 	#inserted 
	     SET 	@CurrentHeaderID = ID = @CurrentHeaderID + 1
	   WHERE 	ISNULL( ID, 0 ) = 0 
				; 

--	Load repository header data from stage data
     EXECUTE 	hwt.usp_LoadRepositoryFromStage 
				@pSourceTable	=	'header' 
				;


--	UPDATE existing labViewStage.Header with trigger data 

	  UPDATE 	hdr 
		 SET	ResultFile			= 	i.ResultFile		
			  , StartTime			= 	i.StartTime		
			  , FinishTime			= 	i.FinishTime		
			  , TestDuration		= 	i.TestDuration	
			  , ProjectName			= 	i.ProjectName		
			  , FirmwareRev			= 	i.FirmwareRev		
			  , HardwareRev			= 	i.HardwareRev		
			  , PartSN				= 	i.PartSN			
			  , OperatorName		= 	i.OperatorName	
			  , TestMode			= 	i.TestMode		
			  , TestStationID		= 	i.TestStationID	
			  , TestName			= 	i.TestName		
			  , TestConfigFile		= 	i.TestConfigFile	
			  , TestCodePathName	= 	i.TestCodePathName
			  , TestCodeRev			= 	i.TestCodeRev			
			  , HWTSysCodeRev		= 	i.HWTSysCodeRev		
			  , KdrivePath			= 	i.KdrivePath			
			  , Comments			= 	i.Comments			
			  , ExternalFileInfo	= 	i.ExternalFileInfo	
			  , IsLegacyXML			= 	i.IsLegacyXML
	    FROM 	labViewStage.header AS hdr
				INNER JOIN #inserted AS i 
						ON i.ID = hdr.ID 
				; 
				
	  
	  INSERT 	labViewStage.header
					( 
						ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName
						  , FirmwareRev, HardwareRev, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile
						  , TestCodePathName, TestCodeRev, HWTSysCodeRev, KdrivePath, Comments, ExternalFileInfo, IsLegacyXML
					)
	  SELECT 	i.ID, i.ResultFile, i.StartTime, i.FinishTime, i.TestDuration, i.ProjectName
				  , i.FirmwareRev, i.HardwareRev, i.PartSN, i.OperatorName, i.TestMode, i.TestStationID
				  , i.TestName, i.TestConfigFile, i.TestCodePathName, i.TestCodeRev, i.HWTSysCodeRev		
				  , i.KdrivePath, i.Comments, i.ExternalFileInfo, i.IsLegacyXML
		FROM 	#inserted AS i
				LEFT JOIN labViewStage.header AS hdr
						ON hdr.ID = i.ID 
	   WHERE	hdr.ID IS NULL 
				; 
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH
