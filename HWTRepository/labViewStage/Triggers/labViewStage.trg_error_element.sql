CREATE TRIGGER	labViewStage.trg_error_element
			ON 	labViewStage.error_element
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	Load trigger data into temp storage
    SELECT * INTO #inserted FROM inserted ;

	
--	Load repository equipment data from stage data
    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = N'error_element' ;
	
--	MERGE trigger data into labViewStage.error_element table 
	 WITH	existing AS
			( 
			  SELECT 	ID
					  , VectorID  
					  , ErrorCode 
					  , ErrorText 
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
												    VectorID    
												  , ErrorCode   
												  , ErrorText   
												) 
				FROM 	labViewStage.error_element AS a 
			   WHERE 	VectorID IN ( SELECT VectorID FROM inserted ) 
			)

		  , src AS 
			(
			  SELECT 	VectorID	
					  , ErrorCode 
					  , ErrorText 
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
												    VectorID    
												  , ErrorCode   
												  , ErrorText   
												) 
				FROM 	inserted
			)
	MERGE 	INTO existing AS e
			USING src AS s 
				ON s.trg_checksum = e.trg_checksum 	
				
	WHEN 	NOT MATCHED BY TARGET 
			THEN  INSERT
					( VectorID, ErrorCode, ErrorText )
				
				  VALUES 
					( s.VectorID, s.ErrorCode, s.ErrorText ) ;
					
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH