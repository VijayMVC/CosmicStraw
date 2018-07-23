CREATE TRIGGER	labViewStage.trg_header
			ON 	labViewStage.header
	INSTEAD OF 	INSERT, UPDATE
/*
***********************************************************************************************************************************

    Procedure:  hwt.trg_header
    Abstract:   Loads header records into staging environment

    Logic Summary
    -------------
    1)	Load trigger data into temp storage
    2)	Load repository header data from stage data
	3) 	INSERT trigger data into labViewStage 	

    
    Revision
    --------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/	
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

     DECLARE 	@CurrentHeaderID int ; 
	
	  SELECT 	@CurrentHeaderID = ISNULL( MAX( ID ), 0 ) FROM labViewStage.header ; 

--	1)	Load trigger data into temp storage
      SELECT 	i.ID                  
			  , i.ResultFile			
			  , i.StartTime           
			  , i.FinishTime          
			  , i.TestDuration        
			  , ProjectName       	=	REPLACE( REPLACE( REPLACE( i.ProjectName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )		
			  , FirmwareRev       	=	REPLACE( REPLACE( REPLACE( i.FirmwareRev, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )		
			  , HardwareRev       	=	REPLACE( REPLACE( REPLACE( i.HardwareRev, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )		
			  , PartSN            	=	REPLACE( REPLACE( REPLACE( i.PartSN, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )      		
			  , OperatorName      	=	REPLACE( REPLACE( REPLACE( i.OperatorName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )		
			  , i.TestMode        	  	
			  , TestStationID     	=	REPLACE( REPLACE( REPLACE( i.TestStationID, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )		
			  , TestName          	=	REPLACE( REPLACE( REPLACE( i.TestName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )			
			  , TestConfigFile    	=	REPLACE( REPLACE( REPLACE( i.TestConfigFile, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )	
			  , TestCodePathName	=	REPLACE( REPLACE( REPLACE( i.TestCodePathName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )	
			  , i.TestCodeRev       
			  , i.HWTSysCodeRev     
			  , KdrivePath        	=	REPLACE( REPLACE( REPLACE( i.KdrivePath, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )		
			  , Comments          	=	REPLACE( REPLACE( REPLACE( i.Comments, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )			
			  , ExternalFileInfo  	=	REPLACE( REPLACE( REPLACE( i.ExternalFileInfo, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )	
			  , i.IsLegacyXML			
			  , i.CreatedDate			
			  , i.UpdatedDate			
		INTO 	#inserted 
		FROM 	inserted AS i
				;
	
	  UPDATE 	#inserted 
	     SET 	@CurrentHeaderID = ID = @CurrentHeaderID + 1
	   WHERE 	ISNULL( ID, 0 ) = 0 
				; 

--	Load repository header data from stage data
     EXECUTE 	hwt.usp_LoadRepositoryFromStage 
					@pSourceTable	=	'header' 
				;


--	UPDATE existing labViewStage.header with trigger data 

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
			  , CreatedDate			=	i.CreatedDate
			  , UpdatedDate			=	SYSDATETIME()
	    FROM 	labViewStage.header AS hdr
				INNER JOIN #inserted AS i 
						ON i.ID = hdr.ID 
				; 
				
	  
	  INSERT 	labViewStage.header
					( 
						ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev
							, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile, TestCodePathName
							, TestCodeRev, HWTSysCodeRev, KdrivePath, Comments, ExternalFileInfo, IsLegacyXML, CreatedDate
					)
	  SELECT 	i.ID, i.ResultFile, i.StartTime, i.FinishTime, i.TestDuration, i.ProjectName
				  , i.FirmwareRev, i.HardwareRev, i.PartSN, i.OperatorName, i.TestMode, i.TestStationID
				  , i.TestName, i.TestConfigFile, i.TestCodePathName, i.TestCodeRev, i.HWTSysCodeRev		
				  , i.KdrivePath, i.Comments, i.ExternalFileInfo, i.IsLegacyXML, i.CreatedDate
		FROM 	#inserted AS i
				LEFT JOIN labViewStage.header AS hdr
						ON hdr.ID = i.ID 
	   WHERE	hdr.ID IS NULL 
				; 
					
END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	IF EXISTS( SELECT 1 FROM deleted ) 
	BEGIN 
		  SELECT	@pErrorData =	(
									  SELECT
												(
												  SELECT	*
													FROM	inserted
															FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
												)
											  , (
												  SELECT	*
													FROM	deleted
															FOR XML PATH( 'deleted' ), TYPE, ELEMENTS XSINIL
												)
											  , (
												  SELECT	*
													FROM	#inserted 
															FOR XML PATH( 'post-process' ), TYPE, ELEMENTS XSINIL
												)
												FOR XML PATH( 'trg_header' ), TYPE
									)
					;
	END 
		ELSE
	BEGIN 
		  SELECT	@pErrorData =	(
									  SELECT
												(
												  SELECT	*
													FROM	inserted
															FOR XML PATH( 'pre-process' ), TYPE, ELEMENTS XSINIL
												)
											  , (
												  SELECT	*
													FROM	#inserted 
															FOR XML PATH( 'post-process' ), TYPE, ELEMENTS XSINIL
												)
												FOR XML PATH( 'trg_header' ), TYPE
									)
					;

	END 

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH