﻿CREATE	PROCEDURE hwt.usp_GetDatasetXML
			(
				@pHeaderID	nvarchar(max)
			)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_GetDatasetXML
	 Abstract:	Returns dataset names and XML representations of input headerIDs


	 Logic Summary
	-------------
	1)	Parse input parameter into temp storage
	2)	Validate input parameters
	3)	Load tags for selected headers into temporary storage
	4)	Load ReqIDs for selected datasets into temporary storage
	5)	SELECT dataset name and XML representation for each Header.HeaderID value in dataset.


	Parameters
	----------
	@pHeaderID	nvarchar(max)	pipe-delimited list of Header.HeaderID values
								must not be null
								must contain only HeaderIDs that exists in system

	Notes
	-----

	FOR XML PATH usage notes:


	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		labViewwStage messaging architecture
								--	updated column names

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

 DECLARE	@p1					sql_variant
		  , @p2					sql_variant
		  , @p3					sql_variant
		  , @p4					sql_variant
		  , @p5					sql_variant
		  , @p6					sql_variant
		  , @pInputParameters	nvarchar(4000)
			;

  SELECT	@pInputParameters	=	(
									  SELECT	[usp_GetDatasetXML.@pHeaderID]	=	@pHeaderID
												FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
									)
			;

BEGIN TRY

	 DECLARE	@recordCount	int ;

--	1)	Parse input parameter into temp storage
	DROP TABLE IF EXISTS #headers ;

	  SELECT	HeaderID = TRY_CONVERT( int, LTRIM( RTRIM( x.Item ) ) )
		INTO	#headers
		FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
	ORDER BY	1
				;

	  SELECT	@recordCount = @@ROWCOUNT ;


--	2)	Validate input parameters
	IF	( @pHeaderID IS NULL ) OR ( @recordCount = 0 )
		BEGIN
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	'Error:	 Input for hwt.GetDatasetXML must contain at least one dataset ID. '
						  , @p1			=	@pInputParameters
						;
		END

	IF	EXISTS( SELECT 1 FROM #headers WHERE HeaderID IS NULL )
		BEGIN
			 DECLARE	@invalidDatasetIDs	nvarchar(max)
					  , @invalidMsg			nvarchar(max)
						;

			  SELECT	@invalidDatasetIDs	=	STUFF
												(
													(
													  SELECT	',' + LTRIM( RTRIM( x.Item ) )
														FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
													   WHERE	ISNUMERIC( LTRIM( RTRIM( x.Item ) ) ) = 0
																	FOR XML PATH( '' ), TYPE
													).value( '.', 'nvarchar(max)' ), 1, 1, ''
												)
						;

			  SELECT	@recordCount = @@ROWCOUNT ;

			IF	( @recordCount > 1 )
				  SELECT	@invalidMsg = 'The following dataset ID is not valid: %1' ;
			ELSE
				  SELECT	@invalidMsg = 'The following %2 dataset IDs are not valid: %1' ;


			EXECUTE	eLog.log_ProcessEventLog	@pProcID	=	@@PROCID
											  , @pMessage	=	@invalidMsg
											  , @p1			=	@invalidDatasetIDs
											  , @p2			=	@recordCount
											  , @p3			=	@pInputParameters
					;
		END


--	3)	Load tags for selected headers into temporary storage
	DROP TABLE IF EXISTS #Tags ;

	  SELECT	HeaderID	=	h.HeaderID
			  , TagType		=	tType.Name
			  , TagName		=	t.Name
		INTO	#Tags
		FROM	#headers AS h
				INNER JOIN	hwt.HeaderTag AS hTag
						ON	hTag.HeaderID = h.HeaderID

				INNER JOIN	hwt.Tag AS t
						ON	hTag.TagID = t.TagID

				INNER JOIN	hwt.TagType AS tType
						ON	tType.TagTypeID = t.TagTypeID
				;



--	4)	Load ReqIDs for selected datasets into temporary storage
	DROP TABLE IF EXISTS #ReqIDs ;

	  SELECT	VectorID	=	v.VectorID
			  , ReqID		=	t.Name
			  , NodeOrder	=	vr.NodeOrder
		INTO	#ReqIDs
		FROM	#headers AS h
				INNER JOIN	hwt.Vector AS v
						ON	v.HeaderID = h.HeaderID

				INNER JOIN	hwt.VectorRequirement AS vr
						ON	vr.VectorID = v.VectorID

				INNER JOIN	hwt.Tag AS t
						ON	t.TagID = vr.TagID
				;

--	5)	SELECT dataset name and XML representation for each Header.HeaderID value in dataset.
--			NCHAR(92) is the '\' character, using the actual character corrupts the code editor syntax highlighting
	  SELECT	DatasetName =	RIGHT( ResultFileName, CHARINDEX( NCHAR(92), REVERSE( h.ResultFileName ) + NCHAR(92) ) - 1 )
			  , DatasetXML	=	(
								  SELECT	(
											  SELECT	Result_File			=	h2.ResultFileName
													  , Start_Time			=	FORMAT( h2.StartTime, 'MMM dd, yyyy HH:mm' )
													  , Finish_Time			=	FORMAT( h2.FinishTime, 'MMM dd, yyyy HH:mm' )
													  , Test_Duration		=	h2.Duration
													  , Project_Name		=	p.TagName
													  , Firmware_Rev		=	fw.TagName
													  , Hardware_Rev		=	hw.TagName
													  , Part_SN				=	sn.TagName
													  , Operator_Name		=	o.TagName
													  , Test_Station_ID		=	h2.TestStationName
													  , Test_Name			=	h2.TestName
													  , Test_Config_File	=	h2.TestConfigFile
													  , Test_Code_Path_Name =	h2.TestCodePath
													  , Test_Code_Rev		=	h2.TestCodeRevision
													  , HWTSys_Code_Rev		=	h2.HWTSysCodeRevision
													  , Kdrive_Path			=	h2.KdrivePath
													  , equipment			=	equipment.xmlData
													  , External_File_Info	=	h2.ExternalFileInfo
													  , options				=	options.xmlData
													  , Comments			=	h2.Comments
													  , LibraryInfo			=	LibraryInfo.xmlData
												FROM	hwt.Header AS h2
														-- Apply tagged data to header attributes
														OUTER APPLY
															(
																  SELECT	TagName
																	FROM	#Tags AS t
																   WHERE	t.HeaderID = h2.HeaderID AND t.TagType = 'Project'
															) AS p

														OUTER APPLY
															(
																  SELECT	TagName
																	FROM	#Tags AS t
																   WHERE	t.HeaderID = h2.HeaderID AND t.TagType = 'FWRevision'
															) AS fw

														OUTER APPLY
															(
																  SELECT	TagName
																	FROM	#Tags AS t
																   WHERE	t.HeaderID = h2.HeaderID AND t.TagType = 'HWIncrement'
															) AS hw

														OUTER APPLY
															(
																  SELECT	TagName
																	FROM	#Tags AS t
																   WHERE	t.HeaderID = h2.HeaderID AND t.TagType = 'DeviceSN'
															) AS sn

														OUTER APPLY
															(
																  SELECT	TagName
																	FROM	#Tags AS t
																   WHERE	t.HeaderID = h2.HeaderID AND t.TagType = 'Operator'
															) AS o

														-- equipment and equipment_element XML
														OUTER APPLY
															(
															  SELECT	Description				=	e.Description
																	  , Asset					=	e.Asset
																	  , Calibration_Due_Date	=	CASE he.CalibrationDueDate
																										WHEN '1900-01-01' THEN 'N/A'
																										ELSE REPLACE( CONVERT( nvarchar(20), he.CalibrationDueDate, 106 ), ' ', '' )
																									END
																	  , Cost_Center				=	e.CostCenter
																FROM	hwt.Equipment AS e
																		INNER JOIN	hwt.HeaderEquipment AS he
																				ON	he.EquipmentID = e.EquipmentID
															   WHERE	he.HeaderID = h2.HeaderID
															ORDER BY	he.NodeOrder
																		FOR XML PATH( 'equipment_element' ), TYPE
															) AS equipment( xmlData )

														-- options, option_element, and appConst_element XML
														OUTER APPLY
															(
															  SELECT	(
																		  SELECT	name	=	o.Name
																				  , type	=	o.DataType
																				  , units	=	o.Units
																				  , value	=	ho.OptionValue
																			FROM	hwt.[Option] AS o
																					INNER JOIN	hwt.HeaderOption AS ho
																							ON	ho.OptionID= o.OptionID
																		   WHERE	ho.HeaderID = h2.HeaderID
																		ORDER BY	ho.NodeOrder
																					FOR XML PATH( 'option_element' ), TYPE
																		)
																	  , (
																		  SELECT	name	=	ac.Name
																				  , type	=	ac.DataType
																				  , units	=	ac.Units
																				  , value	=	ha.AppConstValue
																			FROM	hwt.AppConst AS ac
																					INNER JOIN	hwt.HeaderAppConst AS ha
																							ON	ha.AppConstID = ac.AppConstID
																		   WHERE	ha.HeaderID = h2.HeaderID
																		ORDER BY	ha.NodeOrder
																					FOR XML PATH( 'appConst_element' ), TYPE
																		)
																		FOR XML PATH(''), TYPE
															) AS options( xmlData )

														-- LibraryInfo file XML
														OUTER APPLY
															(
															  SELECT	[@name]		=	l.FileName
																	  , [@rev]		=	l.FileRev
																	  , [@status]	=	l.Status
																	  , [@HashCode] =	l.HashCode
																FROM	hwt.LibraryFile AS l
																		INNER JOIN	hwt.HeaderLibraryFile AS hl
																				ON	hl.LibraryFileID= l.LibraryFileID
															   WHERE	hl.HeaderID = h2.HeaderID
															ORDER BY	hl.NodeOrder
																		FOR XML PATH( 'file' ), TYPE
															) AS LibraryInfo( xmlData )

											   WHERE	h2.HeaderID = h.HeaderID
														FOR XML PATH( 'header' ), TYPE
											)
										  , (
											  SELECT	num				=	v.VectorNumber
													  , ( SELECT vector_element.xmlData )
													  , ( SELECT ReqID.xmlData )
													  , ( SELECT result_element.xmlData )
													  , error_element	=	error_element.xmlData
													  , Timestamp		=	Timestamp.xmlData
												FROM	hwt.Vector AS v

														-- vector_element XML
														OUTER APPLY
															(
															  SELECT	name	=	e.Name
																	  , type	=	e.DataType
																	  , units	=	e.Units
																	  , value	=	ve.ElementValue
																FROM	hwt.Element AS e
																		INNER JOIN	hwt.VectorElement AS ve
																				ON	ve.ElementID = e.ElementID
															   WHERE	ve.VectorID = v.VectorID
															ORDER BY	ve.NodeOrder
																		FOR XML PATH( 'vector_element' ), TYPE
															) AS vector_element( xmlData )

														-- ReqID XML
														OUTER APPLY
															(
															  SELECT	ReqID
																FROM	(
																		  SELECT	ReqID
																				  , NodeOrder
																			FROM	#ReqIDs AS r
																		   WHERE	r.VectorID = v.VectorID

																		   UNION
																		  SELECT	'N/A'
																				  , 1
																			FROM	#ReqIDs AS r
																		   WHERE	NOT EXISTS
																						(
																						  SELECT	1
																							FROM	#ReqIDs AS r
																						   WHERE	r.VectorID = v.VectorID
																						)
																		) AS x
															ORDER BY	NodeOrder
																		FOR XML PATH( '' ), TYPE
															) AS ReqID( xmlData )

														-- result_element XML
														OUTER APPLY
															(
															  SELECT	name	=	r.Name
																	  , type	=	r.DataType
																	  , units	=	r.Units
																	  , (
																		  SELECT	value = vr2.ResultValue
																			FROM	hwt.VectorResult AS vr2
																		   WHERE	vr2.VectorID = vr.VectorID
																						AND vr2.ResultID = vr.ResultID
																						AND vr2.NodeOrder = vr.NodeOrder
																		ORDER BY	vr2.ResultN
																					FOR XML PATH( '' ), TYPE
																		)
																FROM	hwt.Result AS r
																		INNER JOIN	hwt.VectorResult AS vr
																				ON	vr.ResultID = r.ResultID
															   WHERE	vr.VectorID = v.VectorID
																		AND vr.ResultN = 1
															ORDER BY	vr.NodeOrder
																		FOR XML PATH( 'result_element' ), TYPE
															) AS result_element( xmlData )

														-- error_element XML
														OUTER APPLY
															(
															  SELECT	(
																		  SELECT	[test_error/@code]	=	e.ErrorCode
																				  , test_error			=	e.ErrorText
																			FROM	hwt.VectorError AS e
																		   WHERE	e.VectorID = v.VectorID
																						AND e.ErrorType = 1 
																					FOR XML PATH( '' ), TYPE
																		)
																	  , (
																		  SELECT	[data_error/@num]	=	e.ErrorCode
																				  , data_error			=	e.ErrorText
																			FROM	hwt.VectorError AS e
																		   WHERE	e.VectorID = v.VectorID
																						AND e.ErrorType = 2 
																					FOR XML PATH( '' ), TYPE
																		)
																	  , (
																		  SELECT	[input_param_error/@num]	=	e.ErrorCode
																				  , input_param_error			=	e.ErrorText
																			FROM	hwt.VectorError AS e
																		   WHERE	e.VectorID = v.VectorID
																						AND e.ErrorType = 3
																					FOR XML PATH( '' ), TYPE
																		)
															)	AS error_element( xmlData )

														-- Timestamp XML
														OUTER APPLY
															(
															  SELECT	StartTime	=	FORMAT( v.StartTime, 'MMM dd, yyyy HH:mm:ss.fff' )
																	  , EndTime		=	FORMAT( v.EndTime, 'MMM dd, yyyy HH:mm:ss.fff' )
																FROM	hwt.Vector AS v2
															   WHERE	v2.VectorID = v.VectorID
																		FOR XML PATH( '' ), TYPE
															) AS Timestamp( xmlData )

											   WHERE	v.HeaderID = h.HeaderID
											ORDER BY	v.VectorNumber
														FOR XML PATH( 'vector' ), TYPE
											)
											FOR XML PATH( 'root' ), TYPE
								)

		FROM	hwt.Header AS h
				INNER JOIN #headers AS tmp
						ON tmp.HeaderID = h.HeaderID
				;

	RETURN 0 ;

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @p1			=	@pInputParameters
				;

	RETURN 55555 ;

END CATCH