CREATE	PROCEDURE hwt.usp_LoadHeaderFromStage
/*
***********************************************************************************************************************************
	Procedure:	hwt.usp_LoadHeaderFromStage
	Abstract:	Load changed header data from stage to hwt.Header

	Logic Summary
	-------------
	1)	SELECT data into temp storage from labViewStage
	2)	INSERT tags for all headers into temp storage
	3)	INSERT tags for legacy XML data into temp storage
	4)	MERGE header changes from temp storage into hwt.Header
	5)	INSERT tags from temp storage into hwt.Tag
	6)	MERGE new header tag data into hwt.HeaderTag
	7)	UPDATE PublishDate on labViewStage.header


	Parameters
	----------

	Notes
	-----
	When data is being inserted from HWT/LabVIEW, Project and  HWIncrement tags are already created
	When a legacy XML dataset is being entered, Project and HWIncrement tags are loaded here

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		updated messaging architecture
									--	extract all records not published
									--	publish to hwt
									--	update stage data with publish date

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	  CREATE	TABLE #changes
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
					)
				;


--	1)	SELECT data into temp storage from labViewStage
	  INSERT	#changes
					(
						ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev
							, HardwareRev, PartSN, OperatorName, TestMode, TestStationID, TestName
							, TestConfigFile, TestCodePathName, TestCodeRev, HWTSysCodeRev, KdrivePath
							, Comments, ExternalFileInfo, IsLegacyXML, VectorCount
					)
	  SELECT	ID
			  , ResultFile
			  , StartTime
			  , FinishTime
			  , TestDuration
			  , ProjectName			=	REPLACE( REPLACE( REPLACE( ProjectName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , FirmwareRev			=	REPLACE( REPLACE( REPLACE( FirmwareRev, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , HardwareRev			=	REPLACE( REPLACE( REPLACE( HardwareRev, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , PartSN				=	REPLACE( REPLACE( REPLACE( PartSN, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , OperatorName		=	REPLACE( REPLACE( REPLACE( OperatorName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , TestMode
			  , TestStationID		=	REPLACE( REPLACE( REPLACE( TestStationID, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , TestName			=	REPLACE( REPLACE( REPLACE( TestName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , TestConfigFile		=	REPLACE( REPLACE( REPLACE( TestConfigFile, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , TestCodePathName	=	REPLACE( REPLACE( REPLACE( TestCodePathName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , TestCodeRev
			  , HWTSysCodeRev
			  , KdrivePath			=	REPLACE( REPLACE( REPLACE( KdrivePath, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , Comments			=	REPLACE( REPLACE( REPLACE( Comments, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , ExternalFileInfo	=	REPLACE( REPLACE( REPLACE( ExternalFileInfo, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , IsLegacyXML
			  , VectorCount
		FROM	labViewStage.header
	   WHERE	PublishDate IS NULL
				;


--	2)	INSERT tags for all headers into temp storage
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
	--	TagType: OperatorName
	  SELECT	HeaderID	=	tmp.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	tmp.OperatorName
			  , Description =	'Operator extracted from header'
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType

	   WHERE	tType.Name = 'Operator'
					AND ISNULL( tmp.OperatorName, '' ) != ''

	   UNION
	--	TagType: FirmwareRevision
	  SELECT	HeaderID	=	tmp.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	tmp.FirmwareRev
			  , Description =	N'Firmware Rev extracted from header'
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#changes AS tmp
				CROSS JOIN	hwt.TagType AS tType

	   WHERE	tType.Name = N'FWRevision'
					AND ISNULL( tmp.FirmwareRev, '' ) != ''

	   UNION
	--	TagType: DeviceSN
	  SELECT	HeaderID	=	tmp.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	RTRIM( LTRIM( x.Item ) )
			  , Description =	N'Device SN extracted from header'
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#changes AS tmp
				CROSS JOIN	hwt.TagType AS tType

				CROSS APPLY utility.ufn_SplitString
					( tmp.PartSN, ',' ) AS x

	   WHERE	tType.Name = N'DeviceSN'
					AND ISNULL( RTRIM( LTRIM( x.Item ) ), '' ) != ''

	   UNION
	--	TagType: TestMode
	  SELECT	HeaderID	=	tmp.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	tmp.TestMode
			  , Description =	N'Test Mode extracted from header'
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType

	   WHERE	tType.Name = N'TestMode'
					AND ISNULL( tmp.TestMode, '' ) != ''
				;


--	3)	INSERT tags for legacy XML data into temp storage
	  INSERT	#tags
					( HeaderID, TagTypeID, Name, Description, UpdatedBy, TagID )
	--	TagType: Project
	  SELECT	HeaderID	=	tmp.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	tmp.ProjectName
			  , Description =	N'Project extracted from legacy XML'
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType

	   WHERE	tType.Name = 'Project'
					AND ISNULL( tmp.ProjectName, '' ) != ''
					AND tmp.IsLegacyXML = 1

	   UNION
	--	TagType: HW Increment
	  SELECT	HeaderID	=	tmp.ID
			  , TagTypeID	=	tType.TagTypeID
			  , Name		=	tmp.HardwareRev
			  , Description =	N'Hardware Increment extracted from legacy XML'
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		FROM	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType

	   WHERE	tType.Name = N'HWIncrement'
					AND ISNULL( tmp.HardwareRev, '' ) != ''
					AND tmp.IsLegacyXML = 1
				;


--	4)	MERGE header changes from temp storage into hwt.Header
		WITH	cte AS
					(
					  SELECT	HeaderID			=	tmp.ID
							  , ResultFileName		=	LEFT( tmp.ResultFile, 250 )
							  , StartTime			=	CONVERT( datetime, tmp.StartTime, 109 )
							  , FinishTime			=	NULLIF( CONVERT( datetime, tmp.FinishTime, 109 ), '1900-01-01' )
							  , Duration			=	tmp.TestDuration
							  , TestStationID		=	tmp.TestStationID
							  , TestName			=	tmp.TestName
							  , TestConfigFile		=	tmp.TestConfigFile
							  , TestCodePathName	=	tmp.TestCodePathName
							  , TestCodeRevision	=	tmp.TestCodeRev
							  , HWTSysCodeRevision	=	tmp.HWTSysCodeRev
							  , KdrivePath			=	tmp.KdrivePath
							  , Comments			=	tmp.Comments
							  , ExternalFileInfo	=	tmp.ExternalFileInfo
							  , OperatorName		=	tmp.OperatorName
						FROM	#changes AS tmp
					)
	   MERGE	INTO hwt.Header AS tgt
				USING cte AS src
					ON src.HeaderID = tgt.HeaderID
		WHEN	MATCHED
				THEN  UPDATE
							SET tgt.ResultFileName		=	src.ResultFileName
							  , tgt.StartTime			=	src.StartTime
							  , tgt.FinishTime			=	src.FinishTime
							  , tgt.Duration			=	src.Duration
							  , tgt.TestStationName		=	src.TestStationID
							  , tgt.TestName			=	src.TestName
							  , tgt.TestConfigFile		=	src.TestConfigFile
							  , tgt.TestCodePath		=	src.TestCodePathName
							  , tgt.TestCodeRevision	=	src.TestCodeRevision
							  , tgt.HWTSysCodeRevision	=	src.HWTSysCodeRevision
							  , tgt.KdrivePath			=	src.KdrivePath
							  , tgt.Comments			=	src.Comments
							  , tgt.ExternalFileInfo	=	src.ExternalFileInfo
							  , tgt.UpdatedBy			=	src.OperatorName
							  , tgt.UpdatedDate			=	SYSDATETIME()

		WHEN	NOT MATCHED BY TARGET
				THEN  INSERT
							(
								HeaderID, ResultFileName, StartTime
								  , FinishTime, Duration, TestStationName
								  , TestName, TestConfigFile, TestCodePath
								  , TestCodeRevision, HWTSysCodeRevision, KdrivePath
								  , Comments, ExternalFileInfo, UpdatedBy, UpdatedDate
							)
					  VALUES
							(
								src.HeaderID, src.ResultFileName, src.StartTime
								  , src.FinishTime, src.Duration, src.TestStationID
								  , src.TestName, src.TestConfigFile, src.TestCodePathName
								  , src.TestCodeRevision, src.HWTSysCodeRevision, src.KdrivePath
								  , src.Comments, src.ExternalFileInfo, src.OperatorName, SYSDATETIME()
							)
				;


--	5)	INSERT tags from temp storage into hwt.Tag
	  INSERT	hwt.Tag
					( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT
				TagTypeID
			  , Name
			  , Description
			  , IsDeleted		=	0
			  , UpdatedBy
			  , UpdatedDate		=	SYSDATETIME()
		FROM	#tags AS tmp
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


--	6)	MERGE new header tag data into hwt.HeaderTag
	DECLARE		@HeaderID		int
			  , @UpdatedBy	sysname
			  , @TagID			nvarchar(max)
				;


	WHILE EXISTS ( SELECT 1 FROM #tags )
	BEGIN

	  SELECT	TOP 1
				@HeaderID		=	HeaderID
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

	
--	7)	UPDATE PublishDate on labViewStage.header
	  UPDATE	header
		 SET	PublishDate		=	SYSDATETIME()
		FROM	labViewStage.header
	   WHERE	EXISTS ( SELECT 1 FROM #changes AS c WHERE c.ID = header.ID )
				;


RETURN 0 ;

END TRY
BEGIN CATCH

	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadHeaderFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH