CREATE TRIGGER	labViewStage.trg_appConst_element
			ON 	labViewStage.appConst_element
	INSTEAD OF 	INSERT
/*
***********************************************************************************************************************************

    Procedure:  hwt.trg_appConst_element
    Abstract:   Loads appConst_element records into staging environment

    Logic Summary
    -------------
    1)	Load trigger data into temp storage
    2)	Load repository appConst data from stage data
	3) 	INSERT updated trigger data from temp storage into labViewStage 	

    
    Revision
    --------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		disabled trigger ( changed project status to 'None' as well )

***********************************************************************************************************************************
*/	
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

     DECLARE 	@CurrentID int ; 
	
	  SELECT 	@CurrentID = ISNULL( MAX( ID ), 0 ) FROM labViewStage.appConst_element ; 

--	1)	Load trigger data into temp storage
      SELECT 	i.ID
			  , i.HeaderID
			  , Name			=	REPLACE( REPLACE( REPLACE( i.Name, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' ) 
			  , i.Type            
			  , Units           =	REPLACE( REPLACE( REPLACE( i.Units, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , Value           =	REPLACE( REPLACE( REPLACE( i.Value, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , i.CreatedDate
		INTO 	#inserted 
		FROM 	inserted AS i
				;

				
	  UPDATE 	#inserted 
	     SET 	@CurrentID = ID = @CurrentID + 1
	   WHERE 	ISNULL( ID, 0 ) = 0 
				; 
				
--	2)	Load repository appConst data from stage data
     EXECUTE 	hwt.usp_LoadRepositoryFromStage 
					@pSourceTable = N'appConst_element' 
				;
	
--	3) 	INSERT trigger data into labViewStage 	
	  INSERT	labViewStage.appConst_element
					( ID, HeaderID, Name, Type, Units, Value, CreatedDate ) 
	  SELECT 	ID          
			  , HeaderID    
			  , Name        
			  , Type        
			  , Units       
			  , Value   
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
											FOR XML PATH( 'trg_appConst_element' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
GO 

DISABLE TRIGGER labViewStage.trg_appConst_element ON labViewStage.appConst_element ;  
GO 
