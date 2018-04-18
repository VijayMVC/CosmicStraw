CREATE TRIGGER 	labViewStage.trg_vector_element
			ON 	labViewStage.vector_element
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	Load trigger data into temp storage
    SELECT * INTO #inserted FROM inserted ;

	
--	Load repository equipment data from stage data
    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = N'vector_element' ;

--	MERGE trigger data into labViewStage.appConst_element table 
	 WITH	existing AS
			( 
			  SELECT	ID          
					  , VectorID    
					  , Name        
					  , Type        
					  , Units       
					  , Value       
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													VectorID    
												  , Name        
												  , Type        
												  , Units       
												  , Value
												) 
				FROM 	labViewStage.vector_element AS a 
			   WHERE 	VectorID IN ( SELECT VectorID FROM inserted ) 
			)

		  , src AS 
			(
			  SELECT 	VectorID    
					  , Name        
					  , Type        
					  , Units       
					  , Value       
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													VectorID    
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
					( VectorID, Name, Type, Units, Value ) 
				
				  VALUES 
					( s.VectorID, s.Name, s.Type, s.Units, s.Value ) ;
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH