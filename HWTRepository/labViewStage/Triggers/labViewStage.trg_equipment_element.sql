CREATE TRIGGER	labViewStage.trg_equipment_element
			ON 	labViewStage.equipment_element
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	Load trigger data into temp storage
    SELECT * INTO #inserted FROM inserted ;

	
--	Load repository equipment data from stage data
    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = N'equipment_element' ;

	
--	MERGE trigger data into labViewStage.appConst_element table 
	 WITH	existing AS
			( 
			  SELECT 	ID
					  , HeaderID	
					  , Description		
					  , Asset
					  , CalibrationDueDate		
                      , CostCenter
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													HeaderID	
												  , Description		
												  , Asset
												  , CalibrationDueDate		
												  , CostCenter
												) 
				FROM 	labViewStage.equipment_element AS a 
			   WHERE 	HeaderID IN ( SELECT HeaderID FROM inserted ) 
			)

		  , src AS 
			(
			  SELECT 	HeaderID	
					  , Description		
					  , Asset
					  , CalibrationDueDate		
					  , CostCenter
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													HeaderID	
												  , Description		
												  , Asset
												  , CalibrationDueDate		
												  , CostCenter
												) 
				FROM 	inserted
			)
	MERGE 	INTO existing AS e
			USING src AS s 
				ON s.trg_checksum = e.trg_checksum 	
				
	WHEN 	NOT MATCHED BY TARGET 
			THEN  INSERT
					( HeaderID, Description, Asset, CalibrationDueDate, CostCenter ) 
				
				  VALUES 
					( s.HeaderID, s.Description, s.Asset, s.CalibrationDueDate, s.CostCenter ) ;
					
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH