CREATE	PROCEDURE hwt.usp_LoadVectorErrorFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorErrorFromStage
	Abstract:	Load error from test to hwt.VectorError and hwt.HeaderOption

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT error data from labViewStage into hwt.VectorError
	3)	UPDATE PublishDate on labViewStage.error_element
	4)	EXECUTE sp_releaseapplock to release lock

	Parameters
	----------

	Notes
	-----

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling
								updated messaging architecture
									--	extract all records not published
									--	publish to hwt
									--	update stage data with publish date

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON 
;

BEGIN TRY

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.error_element' ) 
;
	 DECLARE 	@Records	TABLE	( RecordID int ) 
; 

--	1)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT	deleted.RecordID 
	    INTO	@Records( RecordID ) 
	   WHERE	ObjectID = @ObjectID
;
				
--	2)	INSERT error data from labViewStage into hwt.VectorError
	  INSERT	hwt.VectorError
					( 
						VectorErrorID, VectorID, ErrorType, ErrorCode, ErrorText
							, ErrorSequenceNumber, UpdatedBy, UpdatedDate 
					)
	  SELECT	DISTINCT 
				i.ID
			  , i.VectorID
			  , i.ErrorType
			  , i.ErrorCode
			  , i.ErrorText
			  , ErrorSequenceNumber	=	i.NodeOrder
			  , h.OperatorName
			  , SYSDATETIME()
		FROM	labViewStage.error_element AS i
				INNER JOIN	@Records 
						ON	RecordID = i.ID

				INNER JOIN	labViewStage.vector AS v
						ON 	v.ID = i.VectorID

				INNER JOIN	labViewStage.header AS h
						ON h.ID = v.HeaderID
;
	RETURN 0 
;
END TRY
BEGIN CATCH
	 DECLARE	@pErrorData xml 
;
	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	lvs.*
												FROM	labViewStage.error_element AS lvs
														INNER JOIN	@Records
																ON	RecordID = lvs.ID
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadVectorErrorFromStage' ), TYPE
								)
;
	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION 
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
;
	RETURN 55555 
;
END CATCH
