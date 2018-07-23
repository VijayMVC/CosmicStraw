CREATE TRIGGER	labViewStage.trg_error_element
			ON 	labViewStage.error_element
	INSTEAD OF 	INSERT
/*
***********************************************************************************************************************************

    Procedure:  hwt.trg_error_element
    Abstract:   Loads error_element records into staging environment

    Logic Summary
    -------------
    1)	Load trigger data into temp storage
    2)	Load repository error data from stage data
	3) 	INSERT updated trigger data from temp storage into labViewStage 	

    
    Revision
    --------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/	
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

     DECLARE 	@CurrentID int ; 
	
	  SELECT 	@CurrentID = ISNULL( MAX( ID ), 0 ) FROM labViewStage.error_element ; 

--	1)	Load trigger data into temp storage
	  SELECT 	i.ID          
			  , i.VectorID
			  , ErrorCode		=	REPLACE( REPLACE( REPLACE( i.ErrorCode, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , ErrorText       =	REPLACE( REPLACE( REPLACE( i.ErrorText, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , i.CreatedDate
		INTO 	#inserted 
		FROM 	inserted AS i
				;

				
	  UPDATE 	#inserted 
	     SET 	@CurrentID = ID = @CurrentID + 1
	   WHERE 	ISNULL( ID, 0 ) = 0 
				; 
				
--	2)	Load repository error data from stage data
     EXECUTE 	hwt.usp_LoadRepositoryFromStage 
					@pSourceTable = N'error_element' 
				;
	
--	3) 	INSERT trigger data into labViewStage 	
	  INSERT	labViewStage.error_element
					( ID, VectorID, ErrorCode, ErrorText, CreatedDate ) 
	  SELECT 	ID          
			  , VectorID
			  , ErrorCode
			  , ErrorText
			  , CreatedDate
		FROM 	#inserted 
				; 
					
END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	*
												FROM	inserted
														FOR XML PATH( 'pre-process' ), TYPE, ELEMENTS XSINIL
											)
										  , (
											  SELECT	*
												FROM	#inserted 
														FOR XML PATH( 'post-process' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'trg_error_element' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH