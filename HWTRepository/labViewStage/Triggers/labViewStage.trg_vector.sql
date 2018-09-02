CREATE TRIGGER
	labViewStage.trg_vector
		ON	labViewStage.vector
		AFTER INSERT
/*
***********************************************************************************************************************************

	Procedure:	labViewStage.trg_vector
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

	IF NOT EXISTS( SELECT 1 FROM inserted ) RETURN ; 
	
	 DECLARE	@pInsertXML		xml ; 

--	1)	Load trigger data into temp storage
	  SELECT	@pInsertXML	=	(
								  SELECT	( 
											  SELECT 	i.ID
													  , i.HeaderID
													  , i.VectorNum
													  , i.Loop
													  , i.ReqID
													  , i.StartTime
													  , i.EndTime
													  , i.CreatedDate
												FROM	inserted AS i
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL 
											)
											FOR XML PATH( 'trg_vector' ), TYPE 
								)
				;


--	2)	EXECUTE proc that loads vector data into repository
	 EXECUTE	hwt.usp_LoadVectorFromStage	
					@pInsertXML = @pInsertXML 
				;

	RETURN ;

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pInsertXML
				;

END CATCH
