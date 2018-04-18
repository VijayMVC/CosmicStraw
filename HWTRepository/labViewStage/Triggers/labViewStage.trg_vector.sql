CREATE TRIGGER	labViewStage.trg_vector
			ON 	labViewStage.vector
	INSTEAD OF 	INSERT, UPDATE
-- invoke process to load repository with stage data
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE 	@CurrentVectorID int ; 
	
	  SELECT 	@CurrentVectorID = ISNULL( MAX( VectorID ), 0 ) FROM hwt.Vector ; 

--	Load trigger data into temp storage
      SELECT 	*
		INTO 	#inserted 
		FROM 	inserted 
				;

	  UPDATE 	#inserted 
	     SET 	@CurrentVectorID = ID = @CurrentVectorID + 1 
	   WHERE 	ISNULL( ID, 0 ) = 0 
				; 
	
--	Load repository vector data from stage data
     EXECUTE 	hwt.usp_LoadRepositoryFromStage 
				@pSourceTable = N'vector' 
				;
	
--	UPDATE existing labViewStage.Vector with trigger data 	
	  UPDATE 	v  
		 SET 	ReqID 	=	v.ReqID 
			  , EndTime	=	v.EndTime			
		FROM	labViewStage.vector AS v 
				INNER JOIN #inserted AS i
					ON i.ID = v.ID
				; 
				
	 
	  INSERT	labViewStage.vector
					( 
					  ID, HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime 
					) 
	  SELECT	i.ID, i.HeaderID, i.VectorNum, i.Loop, i.ReqID, i.StartTime, i.EndTime 
		FROM	#inserted AS i 
				LEFT JOIN labViewStage.vector AS v 
						ON v.ID = i.ID 
	   WHERE 	v.ID IS NULL 
				;
			
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH