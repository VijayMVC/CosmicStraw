CREATE PROCEDURE
	hwt.usp_LoadVectorErrorFromStage
		(
			@pVectorXML		xml
		)
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

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@loadVector		TABLE	( VectorID	int ) ;
	 DECLARE	@lvsRecord		TABLE	( RecordID	int ) ;


--	1)	SELECT the HeaderIDs that need to be published

	  INSERT	@loadVector( VectorID )
	  SELECT	loadVector.xmlData.value( '@value[1]', 'int' )
		FROM	@pVectorXML.nodes('LoadVector/VectorID') AS loadVector(xmlData)
				;


--	2)	SELECT the labViewStage records that need to be published
	  INSERT	@lvsRecord( RecordID )
	  SELECT	ID
		FROM	labViewStage.error_element AS lvs
				INNER JOIN	@loadVector AS h
						ON	h.VectorID = lvs.VectorID
				;

	IF	( @@ROWCOUNT = 0 ) RETURN ;


--	2)	INSERT error data from labViewStage into hwt.VectorError
	  INSERT	hwt.VectorError
					(
						VectorErrorID, VectorID, ErrorType, ErrorCode, ErrorText, ErrorSequenceNumber
					)

	  SELECT	i.ID
			  , i.VectorID
			  , i.ErrorType
			  , i.ErrorCode
			  , i.ErrorText
			  , ErrorSequenceNumber	=	i.NodeOrder
		FROM	labViewStage.error_element AS i
				INNER JOIN	@lvsRecord
						ON	RecordID = i.ID

				INNER JOIN
					labViewStage.vector AS v
						ON v.ID = i.VectorID
				;

	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	lvs.*
												FROM	labViewStage.error_element AS lvs
														INNER JOIN	@lvsRecord
																ON	RecordID = lvs.ID
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadVectorErrorFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH