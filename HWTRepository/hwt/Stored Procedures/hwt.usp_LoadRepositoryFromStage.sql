CREATE 	PROCEDURE hwt.usp_LoadRepositoryFromStage
			(
				@pSourceTable as sysname 
			)
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadRepositoryFromStage
    Abstract:   Detect stage data changes and load them into HWTRepository

    Logic Summary
    -------------
    1)  EXECUTE procedure to extract and apply changes depending on @pSourceTable

    Parameters
    ----------
    @pSourceTable    sysname     This is the table name from which the trigger was fired

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

    DECLARE @isProcessed tinyint = 0 ;

--  1)  EXECUTE procedure to extract and apply changes depending on @pSourceTable

    IF 	( @pSourceTable = 'header' )
    BEGIN
        EXECUTE hwt.usp_LoadHeaderFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'equipment_element' )
    BEGIN
        EXECUTE hwt.usp_LoadEquipmentFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'option_element' )
    BEGIN
        EXECUTE hwt.usp_LoadOptionFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'appConst_element' )
    BEGIN
        EXECUTE hwt.usp_LoadAppConstFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'libraryInfo_file' )
    BEGIN
        EXECUTE hwt.usp_LoadLibraryFileFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'vector' )
    BEGIN
        EXECUTE hwt.usp_LoadVectorFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'vector_element' )
    BEGIN
        EXECUTE hwt.usp_LoadVectorElementFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable = 'result_element' )
	BEGIN
        EXECUTE hwt.usp_LoadVectorResultFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF ( @pSourceTable =  'error_element' )
    BEGIN
        EXECUTE hwt.usp_LoadTestErrorFromStage ;
        SELECT @isProcessed = 1 ;
    END

    IF  ( @isProcessed = 0 )
    BEGIN
		EXECUTE 		eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	'Error:  Input data was not processed, Source table that failed was %1'
						  , @p1			=	@pSourceTable ;
		
    END

	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH