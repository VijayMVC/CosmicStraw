CREATE	PROCEDURE hwt.usp_LoadTestErrorFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadTestErrorFromStage
	Abstract:	Load error from test to hwt.TestError and hwt.HeaderOption

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT error data from labViewStage into hwt.TestError
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

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@updates	table	( ID	int ) ;

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.error_element' ) ;

--	2)	INSERT error data from labViewStage into hwt.TestError
	  INSERT	hwt.TestError
					( TestErrorID, VectorID, ErrorCode, ErrorText, ErrorSequenceNumber, UpdatedBy, UpdatedDate )

	  OUTPUT	inserted.TestErrorID
				INTO @updates( ID )

	  SELECT	i.ID
			  , i.VectorID
			  , i.ErrorCode
			  , i.ErrorText
			  , ErrorSequenceNumber	=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , h.OperatorName
			  , SYSDATETIME()
		FROM	labViewStage.error_element AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN
					labViewStage.vector AS v
						ON v.ID = i.VectorID

				INNER JOIN
					labViewStage.header AS h
						ON h.ID = v.HeaderID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	pa
		FROM	labViewStage.PublishAudit AS pa
				INNER JOIN	@updates AS tmp
						ON	pa.ObjectID = @ObjectID
							AND tmp.ID = pa.RecordID
				;


	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	lvs.*
												FROM	labViewStage.error_element AS lvs
														INNER JOIN	labViewStage.PublishAudit AS pa 
																ON	pa.ObjectID = @ObjectID 
																		AND pa.RecordID = lvs.ID
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