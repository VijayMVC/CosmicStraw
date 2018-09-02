CREATE TRIGGER
	labViewStage.trg_result_element
		ON labViewStage.result_element
		AFTER INSERT
/*
***********************************************************************************************************************************

	Procedure:	labViewStage.trg_result_element
	Abstract:	Loads HeaderID from triggering INSERT into labViewStage.LoadHWTAudit

	Logic Summary
	-------------
	1)	INSERT notification into labViewStage.LoadHWTAudit that the vector needs to be processed


	Notes
	-----
	INSERT does not fail if record already exists on labViewStage.LoadHWTAudit because IGNORE_DUP_KEY is set to ON for this table


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		labViewStage messaging architecture
								--	changed trigger from INSTEAD OF to AFTER
								--	loads labViewStage.LoadHWTAudit instead of loading data into HWT directly

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

IF	NOT EXISTS( SELECT 1 FROM inserted ) RETURN ;

BEGIN TRY

--	1)	INSERT notification into labViewStage.LoadHWTAudit that the header needs to be processed
	  INSERT	labViewStage.LoadHWTVector
	  SELECT	VectorID
		FROM	inserted
				;

END TRY
BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	*
												FROM	inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'trg_result_element' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
