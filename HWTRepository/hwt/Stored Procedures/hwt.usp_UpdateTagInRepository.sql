CREATE PROCEDURE	hwt.usp_UpdateTagInRepository
	(
		@pUserID		sysname			=	NULL
      , @pTagID			int 
      , @pName          nvarchar(50)
      , @pDescription   nvarchar(100)
      , @pIsPermanent   int 			=   0
    )
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_UpdateTagInRepository
    Abstract:   Updates existing tag in repository

    Logic Summary
    -------------
    1)  UPDATE data into hwt.Tag from input parameters 

    Parameters
    ----------
    @pUserID        nvarchar(128)
    @pTagTypeID     int
    @pName          nvarchar(50)
    @pDescription   nvarchar(100)
    @pIsPermanent   int 
	
    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/	
AS
SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

      UPDATE	hwt.Tag
		 SET 	Name			=	@pName          			
			  , Description     =	@pDescription   
			  , UpdatedDate     =	GETDATE()
			  , UpdatedBy       =	COALESCE( @pUserID, CURRENT_USER )
	   WHERE  	TagID = @pTagID ;
	
    RETURN 0 ;

END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) 
		ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH
