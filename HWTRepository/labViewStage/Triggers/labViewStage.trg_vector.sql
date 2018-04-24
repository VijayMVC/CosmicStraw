CREATE TRIGGER	labViewStage.trg_vector
			ON 	labViewStage.vector
	INSTEAD OF 	INSERT
/*
***********************************************************************************************************************************

    Procedure:  hwt.trg_vector
    Abstract:   Loads vector records into staging environment

    Logic Summary
    -------------
    1)	Load trigger data into temp storage
    2)	Load repository vector data from stage data
	3) 	INSERT updated trigger data from temp storage into labViewStage 	

    
    Revision
    --------
    carsoc3     2018-04-27		production release

***********************************************************************************************************************************
*/	
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

     DECLARE 	@CurrentID int ; 
	
	  SELECT 	@CurrentID = ISNULL( MAX( ID ), 0 ) FROM labViewStage.vector ; 

--	1)	Load trigger data into temp storage
	  SELECT 	i.ID          
			  , i.HeaderID    
			  , i.VectorNum
			  , i.Loop
			  , ReqID			=	REPLACE( REPLACE( REPLACE( i.ReqID, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , i.StartTime
			  , i.EndTime
			  , i.CreatedDate 
		INTO 	#inserted 
		FROM 	inserted AS i
				;

				
	  UPDATE 	#inserted 
	     SET 	@CurrentID = ID = @CurrentID + 1
	   WHERE 	ISNULL( ID, 0 ) = 0 
				; 
				
--	2)	Load repository vector data from stage data
     EXECUTE 	hwt.usp_LoadRepositoryFromStage 
					@pSourceTable = N'vector' 
				;
	
--	3) 	INSERT trigger data into labViewStage 	
	  INSERT	labViewStage.vector
					( ID, HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime, CreatedDate )
	  SELECT 	ID          
			  , HeaderID    
			  , VectorNum
			  , Loop
			  , ReqID
			  , StartTime
			  , EndTime
			  , CreatedDate 
		FROM 	#inserted 
				; 
					
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 

END CATCH