CREATE PROCEDURE	hwt.usp_LoadLibraryFileFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadLibraryFileFromStage
    Abstract:   Load changed library files data from stage to hwt.LibraryFile and hwt.HeaderLibraryFile

    Logic Summary
    -------------
    1)	INSERT data into temp storage from trigger
    2)	INSERT new Library File data from temp storage into hwt.LibraryFile
    3)	UPDATE LibraryFileID back into temp storage
    4)	INSERT header libraryFile data from temp storage into hwt.HeaderLibraryFile



    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling	

***********************************************************************************************************************************
*/	
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    --  define temp storage tables
    IF  ( 1 = 0 ) 
        CREATE TABLE	#inserted
						(
							ID          int
						  , HeaderID    int
						  , FileName    nvarchar(400)
						  , FileRev     nvarchar(50)
						  , Status      nvarchar(50)
						  , HashCode    nvarchar(100)
						  , CreatedDate datetime
						) ;

    CREATE TABLE	#changes
					(
						ID              int
					  , HeaderID        int
					  , FileName        nvarchar(400)
					  , FileRev         nvarchar(50)
					  , Status          nvarchar(50)
					  , HashCode        nvarchar(100)
					  , OperatorName    nvarchar(50)
					  , LibraryFileID   int
					) ;

--  1)  INSERT data into temp storage from trigger
      INSERT	INTO #changes
					( ID, HeaderID, FileName, FileRev, Status, HashCode, OperatorName )
      SELECT	i.ID          
              , i.HeaderID    
              , i.FileName    
              , i.FileRev     
              , i.Status      
              , i.HashCode    
			  , h.OperatorName
		FROM	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID ;


--  2)  INSERT new Library File data from temp storage into hwt.LibraryFile
		WITH	cte AS
				(
					  SELECT 	DISTINCT 
								FileName
							  , FileRev
							  , Status
							  , HashCode
						FROM	#changes
						
					  EXCEPT 
					  SELECT 	FileName
							  , FileRev
							  , Status
							  , HashCode
						FROM	hwt.LibraryFile
				)    
	  INSERT	hwt.LibraryFile 
					( FileName, FileRev, Status, HashCode, UpdatedBy, UpdatedDate )
	  SELECT 	DISTINCT 
				cte.FileName
			  , cte.FileRev
			  , cte.Status
			  , cte.HashCode
			  , tmp.OperatorName 
			  , GETDATE() 
		FROM 	cte
				INNER JOIN #changes AS tmp 
						ON tmp.FileName = cte.FileName 
							AND tmp.FileRev  = cte.FileRev        
							AND tmp.Status   = cte.Status         
							AND tmp.HashCode = cte.HashCode    				
				;
				

--  3)	Apply LibraryFileID back into temp storage
      UPDATE	tmp
		 SET	LibraryFileID   =   l.LibraryFileID
		FROM	#changes AS tmp
				INNER JOIN hwt.LibraryFile AS l
						ON l.FileName = tmp.FileName 
							AND l.FileRev = tmp.FileRev        
							AND l.Status = tmp.Status         
							AND l.HashCode = tmp.HashCode       
				;


--  4)  INSERT header libraryFile data from temp storage into hwt.HeaderLibraryFile
     
	  INSERT	hwt.HeaderLibraryFile 
					( HeaderID, LibraryFileID, UpdatedBy, UpdatedDate )
	  SELECT 	HeaderID
			  , LibraryFileID
			  , OperatorName 
			  , GETDATE() 
		FROM 	#changes 
				;

	RETURN 0 ; 
	
END TRY

BEGIN CATCH
	 DECLARE	@pErrorData	xml ; 

      SELECT	@pErrorData	=	( 
								  SELECT	
											(
											  SELECT	* 
											    FROM	#inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
										  , (
											  SELECT	* 
											    FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadLibraryFileFromStage' ), TYPE
								)
				;

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	 EXECUTE	eLog.log_CatchProcessing 
					@pProcID 	=	@@PROCID 
				  , @pErrorData	=	@pErrorData 
				; 
	 
	RETURN 55555 ; 

END CATCH
