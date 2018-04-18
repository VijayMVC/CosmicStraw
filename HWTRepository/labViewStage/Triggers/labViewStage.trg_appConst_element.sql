CREATE TRIGGER	labViewStage.trg_appConst_element
			ON 	labViewStage.appConst_element
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	Load trigger data into temp storage
    SELECT * INTO #inserted FROM inserted ;

--	Load repository appConst data from stage data
    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = N'appConst_element' ;
	
--	MERGE trigger data into labViewStage.appConst_element table 
	 WITH	existing AS
			( 
			  SELECT 	ID
					  , HeaderID	
					  , Name		
					  , Type		
					  , Units		
                      , Value		
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													HeaderID	
												  , Name		
												  , Type		
												  , Units		
												  , Value	
												) 
				FROM 	labViewStage.appConst_element AS a 
			   WHERE 	HeaderID IN ( SELECT HeaderID FROM inserted ) 
			)

		  , src AS 
			(
			  SELECT 	HeaderID	
					  , Name		
					  , Type		
					  , Units		
                      , Value		
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													HeaderID	
												  , Name		
												  , Type		
												  , Units		
												  , Value	
												) 
				FROM 	inserted
			)
	MERGE 	INTO existing AS e
			USING src AS s 
				ON s.trg_checksum = e.trg_checksum 	
				
	WHEN 	NOT MATCHED BY TARGET 
			THEN  INSERT
					( HeaderID, Name, Type, Units, Value ) 
				
				  VALUES 
					( s.HeaderID, s.Name, s.Type, s.Units, s.Value ) ;
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH