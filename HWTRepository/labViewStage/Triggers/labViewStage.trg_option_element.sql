CREATE TRIGGER	labViewStage.trg_option_element
			ON 	labViewStage.option_element
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	Load trigger data into temp storage
    SELECT * INTO #inserted FROM inserted ;

	
--	Load repository equipment data from stage data
    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = N'option_element' ;

	
--	MERGE trigger data into labViewStage.option_element table 
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
				FROM 	labViewStage.option_element AS a 
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