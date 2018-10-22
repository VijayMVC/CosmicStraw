CREATE	PROCEDURE utility.usp_GetExcelAddIns
/*
***********************************************************************************************************************************

	Procedure:	utility.usp_GetExcelAddIns
	Abstract:	Return list of available Excel Add-ins from Repository database

	Logic Summary
	-------------

	Parameters
	----------

	Notes
	-----

	Revision
	--------
	carsoc3		2018-10-31		Enhanced User Interface functionality

***********************************************************************************************************************************
*/
AS

SET NOCOUNT, XACT_ABORT ON
;
BEGIN TRY

  SELECT	DisplayName
		  , AddInPath		=	CompletePath
		  , ExcelSubName
	FROM	utility.ExcelAddIn
ORDER BY	DisplayOrder
;

  RETURN 0
;

END TRY
BEGIN CATCH

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
;
	RETURN 55555
;
END CATCH
