CREATE	PROCEDURE hwt.usp_LoadTestErrorFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadTestErrorFromStage
	Abstract:	Load error from test to hwt.TestError and hwt.HeaderOption

	Logic Summary
	-------------
	1)	INSERT error data into hwt.TestError

	Parameters
	----------


	Notes
	-----


	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	IF	( 1 = 0 )
		CREATE TABLE	#inserted
						(
							ID	int
						  , VectorID	int
						  , ErrorCode	int
						  , ErrorText	nvarchar(max)
						  , CreatedDate datetime
						)
						;


--	1)	INSERT error data from trigger into hwt.TestError
	  INSERT	hwt.TestError
					( VectorID, ErrorCode, ErrorText, UpdatedBy, UpdatedDate )
	  SELECT	tmp.VectorID
			  , tmp.ErrorCode
			  , tmp.ErrorText
			  , h.OperatorName
			  , GETDATE()
		FROM	#inserted AS tmp
				INNER JOIN
					labViewStage.vector AS v
						ON v.ID = tmp.VectorID

				INNER JOIN
					labViewStage.header AS h
						ON h.ID = v.HeaderID
	   WHERE	NOT EXISTS
				(
				  SELECT	1
					FROM	hwt.TestError AS te
				   WHERE	te.VectorID = tmp.VectorID
							AND te.ErrorCode = tmp.ErrorCode
							AND te.ErrorText = tmp.ErrorText
				)
				;

	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	*
												FROM	#inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadTestErrorFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH