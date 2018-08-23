CREATE TRIGGER	labViewStage.trg_vector
			ON	labViewStage.vector
		 AFTER	INSERT
/*
***********************************************************************************************************************************

	Procedure:	hwt.trg_vector
	Abstract:	Loads vector records from labViewStage into repository

	Logic Summary
	-------------
	1)	Load trigger data into temp storage
	2)	EXECUTE proc that loads vector data into repository


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling
								labViewStage messaging architecture

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

--	1)	Load trigger data into temp storage
	  SELECT	i.ID
			  , i.HeaderID
			  , i.VectorNum
			  , i.Loop
			  , i.ReqID			
			  , i.StartTime
			  , i.EndTime
			  , i.CreatedDate
		INTO	#inserted
		FROM	inserted AS i
				;


--	2)	EXECUTE proc that loads vector data into repository
	 EXECUTE	hwt.usp_LoadVectorFromStage ;

	RETURN ;


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
											FOR XML PATH( 'trg_vector' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
