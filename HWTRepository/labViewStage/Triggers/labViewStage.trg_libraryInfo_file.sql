CREATE TRIGGER	labViewStage.trg_libraryInfo_file
			ON 	labViewStage.libraryInfo_file
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	Load trigger data into temp storage
    SELECT * INTO #inserted FROM inserted ;

	
--	Load repository equipment data from stage data
    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = N'libraryInfo_file' ;

	
--	MERGE trigger data into labViewStage.appConst_element table 
	 WITH	existing AS
			( 
			  SELECT 	ID
					  , HeaderID	
					  , FileName		
					  , FileRev
					  , Status
                      , HashCode
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													HeaderID	
												  , FileName		
												  , FileRev
												  , Status
												  , HashCode												
												) 
				FROM 	labViewStage.libraryInfo_file AS a 
			   WHERE 	HeaderID IN ( SELECT HeaderID FROM inserted ) 
			)

		  , src AS 
			(
			  SELECT 	HeaderID	
					  , FileName		
					  , FileRev
					  , Status
					  , HashCode	
					  , trg_checksum	= 	BINARY_CHECKSUM
												( 
													HeaderID	
												  , FileName		
												  , FileRev
												  , Status
												  , HashCode	
												) 
				FROM 	inserted
			)
	MERGE 	INTO existing AS e
			USING src AS s 
				ON s.trg_checksum = e.trg_checksum 	
				
	WHEN 	NOT MATCHED BY TARGET 
			THEN  INSERT
					( HeaderID, FileName, FileRev, Status, HashCode	) 
				
				  VALUES 
					( s.HeaderID, s.FileName, s.FileRev, s.Status, s.HashCode ) ;
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH