CREATE PROCEDURE
	xmlStage.usp_CompareStageData
		(
			@pHeaderID		int
		)
/*
***********************************************************************************************************************************

	Procedure:	xmlStage.usp_CompareStageData
	 Abstract:	Compares contents of xmlStage data with contents of labViewStage data, reports out differences as errors


	 Logic Summary
	-------------
	1)	Iterate for 10 minutes until datasets are ready for comparison
	2)	Compare header tables and report errors
	3)	Compare appConst_element tables and report errors
	4)	Compare equipment_element tables and report errors
	5)	Compare option_element tables and report errors
	6)	Compare libraryInfo_file tables and report errors
	7)	Compare vector tables and report errors
	8)	Compare vector_element tables and report errors
	9)	Compare result_element tables and report errors
   10)	Compare error_element tables and report errors


	Parameters
	----------
	@pHeaderID	int		DatasetID to be compared

	Notes
	-----

	Revision
	--------
	carsoc3		2018-08-31		labViewwStage messaging architecture

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON
;
BEGIN TRY

 DECLARE	@tableErrorsList		nvarchar(1000)	=	N''
		  , @errorsFound			int				=	0

		  , @vectorCount			int
		  , @readyForProcessing		int				=	0
		  , @vectorCountRetries		int				=	0
;

--	1)	Iterate for 10 minutes until datasets are ready for comparison
	WHILE( @VectorCountRetries < 10 )
	BEGIN
		  SELECT	@VectorCount	=	COUNT(1)
			FROM	labViewStage.vector
		   WHERE	HeaderID = @pHeaderID
;
		  SELECT	@VectorCountRetries	=	10
				  , @ReadyForProcessing	=	1
			FROM	labViewStage.header
		   WHERE	ID = @pHeaderID
					AND VectorCount = @VectorCount
;
		IF	( @VectorCountRetries < 10 )
		BEGIN
			SELECT	@VectorCountRetries = @VectorCountRetries + 1
;
		   WAITFOR	DELAY '00:01:00'
;
		END
	END

	IF(	@ReadyForProcessing = 0 )
	BEGIN
		EXECUTE		eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Dataset Compare failed after 10 minutes DatasetID = %1'
						  , @p1			=	@pHeaderID
;
	END

--	1)	Compare header tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_header_Compare WHERE ID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', header'
;

--	2)	Compare appConst_element tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_appConst_element_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', appConst_element'
;

--	3)	Compare equipment_element tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_equipment_element_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', equipment_element'
;

--	4)	Compare option_element tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_option_element_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', option_element'
;

--	5)	Compare libraryInfo_file tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_libraryInfo_file_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', libraryInfo_file'
;

--	6)	Compare vector tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_vector_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', vector'
;

--	7)	Compare vector_element tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_vector_element_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', vector_element'
;

--	8)	Compare result_element tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_result_element_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', result_element'
;

--	9)	Compare error_element tables and report errors
	IF	EXISTS( SELECT 1 FROM xmlStage.vw_error_element_Compare WHERE HeaderID = @pHeaderID )
		  SELECT	@errorsFound		=	1
				  , @tableErrorsList	=	@tableErrorsList + N', error_element'
;

--	10)	If errors were found, format output report and raise error
	IF	@errorsFound = 1
	BEGIN
		 DECLARE	@pErrorData xml
				  , @pMessage	nvarchar(2048)
;
		  SELECT	@pErrorData	=	(
									  SELECT	[@DatasetID]	=	@pHeaderID
											  , (
												  SELECT	ID
														  , TableName
														  , ResultFile
														  , StartTime
														  , FinishTime
														  , TestDuration
														  , ProjectName
														  , FirmwareRev
														  , HardwareRev
														  , PartSN
														  , OperatorName
														  , TestMode
														  , TestStationID
														  , TestName
														  , TestConfigFile
														  , TestCodePathName
														  , TestCodeRev
														  , HWTSysCodeRev
														  , KdrivePath
														  , Comments
														  , ExternalFileInfo
														  , VectorCount
													FROM	xmlStage.vw_header_Compare
												   WHERE	ID = @pHeaderID
												ORDER BY	1,2
															FOR XML AUTO, ROOT( 'header' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , NodeOrder
														  , TableName
														  , Asset
														  , Description
														  , CalibrationDueDate
														  , CostCenter
													FROM	xmlStage.vw_equipment_element_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3
															FOR XML AUTO, ROOT( 'equipment_element' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , NodeOrder
														  , TableName
														  , Name
														  , Type
														  , Units
														  , Value
													FROM	xmlStage.vw_option_element_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3
															FOR XML AUTO, ROOT( 'option_element' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , NodeOrder
														  , TableName
														  , Name
														  , Type
														  , Units
														  , Value
													FROM	xmlStage.vw_appConst_element_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3
															FOR XML AUTO, ROOT( 'appConst_element' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , TableName
														  , NodeOrder
														  , FileName
														  , FileRev
														  , Status
														  , HashCode
													FROM	xmlStage.vw_libraryInfo_file_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3
															FOR XML AUTO, ROOT( 'libraryInfo' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , TableName
														  , VectorNum
														  , Loop
														  , ReqID
														  , StartTime
														  , EndTime
													FROM	xmlStage.vw_vector_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3, 4, 5, 6
															FOR XML AUTO, ROOT( 'vector' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , VectorNum
														  , Loop
														  , StartTime
														  , NodeOrder
														  , TableName
														  , Name
														  , Type
														  , Units
														  , Value
													FROM	xmlStage.vw_vector_element_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3, 4, 5, 6
															FOR XML AUTO, ROOT( 'vector_element' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , VectorNum
														  , Loop
														  , StartTime
														  , NodeOrder
														  , TableName
														  , Name
														  , Type
														  , Units
														  , Value
													FROM	xmlStage.vw_result_element_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3, 4, 5, 6
															FOR XML AUTO, ROOT( 'result_element' ), TYPE
												)
											  , (
												  SELECT	HeaderID
														  , VectorNum
														  , Loop
														  , StartTime
														  , NodeOrder
														  , TableName
														  , ErrorType
														  , ErrorCode
														  , ErrorText
													FROM	xmlStage.vw_error_element_Compare
												   WHERE	HeaderID = @pHeaderID
												ORDER BY	1, 2, 3, 4, 5, 6
															FOR XML AUTO, ROOT( 'error_element' ), TYPE
												)
												FOR XML PATH( 'usp_CompareStageData' ), TYPE
									)
;
		  SELECT	@tableErrorsList = STUFF( @tableErrorsList, 1, 2, '' )
;
		  SELECT	@pMessage	=	N'Dataset Compare failed for dataset ID: ' + CONVERT( nvarchar(20), @pHeaderID ) + '.' + NCHAR(13) + NCHAR(10) +
										N'Stage table(s) that failed comparison:  ' + @tableErrorsList + NCHAR(13) + NCHAR(10) +
										N'See Error Data for full report. '
;
		 RAISERROR( @pMessage, 16, 0 )
;
	END

	RETURN 0
;
END TRY
BEGIN CATCH
	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID		=	@@PROCID
				  , @pErrorData		=	@pErrorData
;
	RETURN 55555
;
END CATCH
