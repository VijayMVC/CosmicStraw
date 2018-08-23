CREATE	PROCEDURE hwt.usp_LoadHeaderFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadHeaderFromStage
	Abstract:	Load changed header data from stage to hwt.Header

	Logic Summary
	-------------
	1)	UPDATE data changes from temp storage into hwt.Header
	2)	INSERT	new headers from temp storage into hwt.Header
	3)	INSERT tags for all headers into temp storage
	4)	INSERT tags for legacy XML data into temp storage
	5)	INSERT tags from temp storage into hwt.Tag
	6)	Assign new tags to datasets by iterating over temp storage


	Parameters
	----------

	Notes
	-----
	When data is being inserted from HWT/LabVIEW, Project and  HWIncrement tags are already created
	When a legacy XML dataset is being entered, Project and HWIncrement tags are loaded here

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		labViewStage messaging architecture
								--	extract data from temp storage
								--	publish to hwt

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	IF	( 1 = 0 )
		CREATE	TABLE #inserted
					(
						ID					int
					  , ResultFile			nvarchar(1000)
					  , StartTime			nvarchar(100)
					  , FinishTime			nvarchar(100)
					  , TestDuration		nvarchar(100)
					  , ProjectName			nvarchar(100)
					  , FirmwareRev			nvarchar(100)
					  , HardwareRev			nvarchar(100)
					  , PartSN				nvarchar(100)
					  , OperatorName		nvarchar(100)
					  , TestMode			nvarchar(50)
					  , TestStationID		nvarchar(100)
					  , TestName			nvarchar(250)
					  , TestConfigFile		nvarchar(400)
					  , TestCodePathName	nvarchar(400)
					  , TestCodeRev			nvarchar(100)
					  , HWTSysCodeRev		nvarchar(100)
					  , KdrivePath			nvarchar(400)
					  , Comments			nvarchar(max)
					  , ExternalFileInfo	nvarchar(max)
					  , IsLegacyXML			int
					  , VectorCount			int
					  , CreatedDate			datetime2(3)
					  , UpdatedDate			datetime2(3)
					)
				;


--	1)	UPDATE data changes from temp storage into hwt.Header
	  UPDATE	hwtData
		 SET	hwtData.ResultFileName		=	LEFT( i.ResultFile, 250 )
			  , hwtData.StartTime			=	CONVERT( datetime, i.StartTime, 109 )
			  , hwtData.FinishTime			=	NULLIF( CONVERT( datetime, i.FinishTime, 109 ), '1900-01-01' )
			  , hwtData.Duration			=	i.TestDuration
			  , hwtData.TestStationName		=	i.TestStationID
			  , hwtData.TestName			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.TestName, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , hwtData.TestConfigFile		=	i.TestConfigFile
			  , hwtData.TestCodePath		=	i.TestCodePathName
			  , hwtData.TestCodeRevision	=	i.TestCodeRev
			  , hwtData.HWTSysCodeRevision	=	i.HWTSysCodeRev
			  , hwtData.KdrivePath			=	i.KdrivePath
			  , hwtData.Comments			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.Comments, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , hwtData.ExternalFileInfo	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.ExternalFileInfo, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , hwtData.UpdatedBy			=	i.OperatorName
			  , hwtData.UpdatedDate			=	SYSDATETIME()
		FROM	hwt.Header AS hwtData
				INNER JOIN	#inserted AS i
						ON	i.ID = hwtData.HeaderID
				;


--	2)	INSERT	new headers from temp storage into hwt.Header
	  INSERT	hwt.Header
					(
					  HeaderID, ResultFileName, StartTime, FinishTime, Duration, TestStationName
						, TestName, TestConfigFile, TestCodePath, TestCodeRevision, HWTSysCodeRevision
						, KdrivePath, Comments, ExternalFileInfo, UpdatedBy, UpdatedDate
					)

	  SELECT	HeaderID			=	i.ID
			  , ResultFileName		=	LEFT( i.ResultFile, 250 )
			  , StartTime			=	CONVERT( datetime, i.StartTime, 109 )
			  , FinishTime			=	NULLIF( CONVERT( datetime, i.FinishTime, 109 ), '1900-01-01' )
			  , Duration			=	i.TestDuration
			  , TestStationName		=	i.TestStationID
			  , TestName			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.TestName, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , TestConfigFile		=	i.TestConfigFile
			  , TestCodePath		=	i.TestCodePathName
			  , TestCodeRevision	=	i.TestCodeRev
			  , HWTSysCodeRevision	=	i.HWTSysCodeRev
			  , KdrivePath			=	i.KdrivePath
			  , Comments			=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.Comments, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , ExternalFileInfo	=	REPLACE( REPLACE( REPLACE( REPLACE( REPLACE( i.ExternalFileInfo, '&apos;', '''' ), '&lt;', '<' ), '&gt;', '>' ), '&quot;', '"' ), '&amp;', '&' )
			  , UpdatedBy			=	i.OperatorName
			  , UpdatedDate			=	SYSDATETIME()
		FROM	#inserted AS i
	   WHERE	NOT EXISTS( SELECT 1 FROM hwt.Header AS h WHERE h.HeaderID = i.ID )
				;


--	3)	INSERT tags for all headers into temp storage
		--	TagTypes: OperatorName, FirmwareRevision, DeviceSN, TestMode
	DROP TABLE IF EXISTS #tags ;

	  CREATE	TABLE #tags
					(
						HeaderID		int
					  , TagTypeID		int
					  , Name			nvarchar(50)
					  , Description		nvarchar(200)
					  , UpdatedBy		sysname
					  , TagID			int
					)
				;

	  INSERT	#tags
					( HeaderID, TagTypeID, Name, Description, UpdatedBy, TagID )
	  SELECT	HeaderID	=	i.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	i.OperatorName
			  , Description =	'Operator extracted from header'
			  , UpdatedBy	=	i.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#inserted AS i
				CROSS JOIN hwt.TagType AS tType
	   WHERE	tType.Name = 'Operator'
					AND ISNULL( i.OperatorName, '' ) != ''

	   UNION
	  SELECT	HeaderID	=	i.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	i.FirmwareRev
			  , Description =	N'Firmware Rev extracted from header'
			  , UpdatedBy	=	i.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#inserted AS i
				CROSS JOIN	hwt.TagType AS tType
	   WHERE	tType.Name = N'FWRevision'
					AND ISNULL( i.FirmwareRev, '' ) != ''

	   UNION
	  SELECT	HeaderID	=	i.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	RTRIM( LTRIM( x.Item ) )
			  , Description =	N'Device SN extracted from header'
			  , UpdatedBy	=	i.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#inserted AS i
				CROSS JOIN	hwt.TagType AS tType

				CROSS APPLY utility.ufn_SplitString
					( i.PartSN, ',' ) AS x
	   WHERE	tType.Name = N'DeviceSN'
					AND ISNULL( RTRIM( LTRIM( x.Item ) ), '' ) != ''

	   UNION
	  SELECT	HeaderID	=	i.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	i.TestMode
			  , Description =	N'Test Mode extracted from header'
			  , UpdatedBy	=	i.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#inserted AS i
				CROSS JOIN hwt.TagType AS tType
	   WHERE	tType.Name = N'TestMode'
					AND ISNULL( i.TestMode, '' ) != ''
				;


--	4)	INSERT tags for legacy XML data into temp storage
		--	TagTypes: Project, HW Increment
	IF	EXISTS( SELECT 1 FROM #inserted WHERE IsLegacyXML = 1 )
		BEGIN
			  INSERT	#tags
							( HeaderID, TagTypeID, Name, Description, UpdatedBy, TagID )
			  SELECT	HeaderID	=	i.ID
					  , TagTypeID	=	tType.TagTypeID
					  , Name		=	i.ProjectName
					  , Description =	N'Project extracted from legacy XML'
					  , UpdatedBy	=	i.OperatorName
					  , TagID		=	CONVERT( int, NULL )
				FROM	#inserted AS i
						CROSS JOIN hwt.TagType AS tType
			   WHERE	tType.Name = 'Project'
							AND ISNULL( i.ProjectName, '' ) != ''
							AND i.IsLegacyXML = 1

			   UNION
			  SELECT	HeaderID	=	i.ID
					  , TagTypeID	=	tType.TagTypeID
					  , Name		=	i.HardwareRev
					  , Description =	N'Hardware Increment extracted from legacy XML'
					  , UpdatedBy	=	i.OperatorName
					  , TagID		=	CONVERT( int, NULL )
				FROM	#inserted AS i
						CROSS JOIN hwt.TagType AS tType
			   WHERE	tType.Name = N'HWIncrement'
							AND ISNULL( i.HardwareRev, '' ) != ''
							AND i.IsLegacyXML = 1
						;
		END


--	5)	INSERT tags from temp storage into hwt.Tag
	  INSERT	hwt.Tag
					( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				TagTypeID
			  , Name
			  , Description
			  , IsDeleted		=	0
			  , UpdatedBy		=	x.UpdatedBy
			  , UpdatedDate		=	SYSDATETIME()
		FROM	#tags AS tmp
				OUTER APPLY
					(
						  SELECT	TOP 1
									UpdatedBy
							FROM	#tags AS t
						   WHERE	t.TagTypeID = tmp.TagTypeID
										AND t.Name = tmp.Name
						ORDER BY	HeaderID
					) as x
	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.Tag AS tag
					   WHERE	tag.TagTypeID = tmp.TagTypeID
									AND tag.Name = tmp.Name
					)
				;

	--	Apply new TagID back into temp storage
	  UPDATE	tmp
		 SET	TagID	=	tag.TagID
		FROM	#tags AS tmp
				INNER JOIN
					hwt.Tag AS tag
						ON tag.TagTypeID = tmp.TagTypeID
							AND tag.Name = tmp.Name
				;


--	6)	Assign new tags to datasets by iterating over temp storage
	DECLARE		@HeaderID		int
			  , @UpdatedBy		sysname
			  , @TagID			nvarchar(max)
				;


	WHILE EXISTS ( SELECT 1 FROM #tags )
		BEGIN

		  SELECT	TOP 1
					@HeaderID	=	HeaderID
				  , @UpdatedBy	=	UpdatedBy
			FROM	#tags
					;

		  SELECT	@TagID		=	STUFF
										(
											(
											  SELECT	N'|' + CONVERT( nvarchar(20), t.TagID )
												FROM	#tags AS t
											   WHERE	t.HeaderID = @HeaderID
														FOR XML PATH (''), TYPE
											).value('.', 'nvarchar(max)'), 1, 1, ''
										)
					;

		 EXECUTE	hwt.usp_AssignTagsToDatasets
						@pUserID	= @UpdatedBy
					  , @pHeaderID	= @HeaderID
					  , @pTagID		= @TagID
					  , @pNotes		= 'Tag assigned during header load.'
					;

		  DELETE	#tags
		   WHERE	HeaderID = @HeaderID
					;

		END


	RETURN 0 ;

END TRY

BEGIN CATCH

	 DECLARE	@pErrorData xml ;

	IF	( OBJECT_ID( 'tempdb..#inserted' ) IS NOT NULL )
		BEGIN
		  SELECT	@pErrorData =	(
									  SELECT	(
												  SELECT	*
													FROM	#inserted
															FOR XML PATH( 'inserted_from_trigger' ), TYPE, ELEMENTS XSINIL
												)
												FOR XML PATH( 'usp_LoadHeaderFromStage' ), TYPE
									)
					;
		END

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH