CREATE PROCEDURE hwt.usp_GetAssetNumbers
/*
***********************************************************************************************************************************

  Procedure:	hwt.usp_GetAssetNumbers
   Abstract:  	returns all available equipment in the HWT Repository
	
	
    Logic Summary
    -------------

    Parameters
    ----------
	 
    Notes
    -----

    Revision
    --------
    carsoc3     2018-4-27		Production release 
	
***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ; 

BEGIN TRY


  SELECT 	EquipmentID			
		  , AssetNumber			=   Asset
	FROM 	hwt.Equipment 
ORDER BY 	AssetNumber ;

  RETURN 	0 ; 

END TRY
BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) 
		ROLLBACK TRANSACTION ; 
	
	  EXECUTE	eLog.log_CatchProcessing	@pProcID = @@PROCID ; 
	
	RETURN 55555 ; 

END CATCH	
