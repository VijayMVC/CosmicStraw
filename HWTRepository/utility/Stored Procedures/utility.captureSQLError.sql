CREATE PROCEDURE 
	utility.captureSQLError( 
		@ErrorLogID int	= 	0 	OUTPUT 
	) 
/*
***********************************************************************************************************************************

    Procedure:  utility.captureSQLError
    Abstract:   Logs error data into permanent database storage, returns errorID to CATCH block that invoked error

    Logic Summary
    -------------

	
    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS                               

SET XACT_ABORT, NOCOUNT ON ;

SELECT	@ErrorLogID 	=	0 ;

BEGIN TRY

IF 	ERROR_NUMBER() IS NULL
    RETURN ;

IF 	XACT_STATE() = -1
BEGIN
	PRINT 
		'Cannot log error since the current transaction is in an uncommittable state. ' 
            + 'Rollback the transaction before executing captureSQLError in order to successfully log error information.';
    RETURN ;
END

INSERT INTO 
	utility.ErrorLog( 
		UserName
	  , ErrorNumber
	  , ErrorSeverity		
      , ErrorState		
      , ErrorProcedure	
      , ErrorLine		
      , ErrorMessage ) 
SELECT 
	UserName		=	CONVERT(sysname, CURRENT_USER)
  , ErrorNumber     =	ERROR_NUMBER()
  , ErrorSeverity	=	ERROR_SEVERITY()
  , ErrorState		=	ERROR_STATE()
  , ErrorProcedure	=	ERROR_PROCEDURE()
  , ErrorLine		=	ERROR_LINE()
  , ErrorMessage 	=	ERROR_MESSAGE() ; 

SELECT 	@ErrorLogID = 	@@IDENTITY ;
END TRY

BEGIN CATCH
	PRINT 'An error occurred in stored procedure utility.captureSQLError: ' ;
    EXECUTE utility.printSQLError ;
    RETURN -1 ;
END CATCH

