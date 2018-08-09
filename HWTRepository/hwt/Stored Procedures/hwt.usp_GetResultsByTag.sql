CREATE	PROCEDURE hwt.usp_GetResultsByTag
			(
				@pHeaderID			nvarchar(max)	=	NULL
			  , @pTestName			nvarchar(max)	=	NULL
			  , @pStartTime			datetime		=	NULL
			  , @pEndTime			datetime		=	NULL
			  , @pIncludeErrors		int				=	NULL
			  , @pIncludeIgnored	int				=	NULL
			  , @pTags				nvarchar(max)	=	NULL
			  , @pSearchTerms		nvarchar(max)	=	NULL
			  , @pDebug				int				=	0
			)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_GetResultsByTag
	Abstract:	Given a set of search parameters, return datasets that match search parameters

	Logic Summary
	-------------


	Parameters
	----------
	@pHeaderID			nvarchar(max)	Specific Header ID ( supports wildcards )
	@pTestName			nvarchar(max)	Specific Test Name ( supports wildcards )
	@pStartTime			datetime		Specifies earliest Start Date for test
	@pEndTime			datetime		Specifies latest Start Date for test
	@pIncludeErrors		int				If set to 1, tests with errors will be included in search results
	@pIncludeIgnored	int				If set to 1, tests with user-defined tag of Ignore will be included in results
	@pTags				nvarchar(max)	Pipe-delimited list of tags to include in search
											** Search rules defined below
	@pSearchTerms		nvarchar(max)	Space-delimited list of search terms to include in search
											** Search rules defined below

	@pAssetNumbers		nvarchar(max)	Space-delimited list of asset numbers to include in search
											** Search rules defined below

	@pDebug				int				Used for debugging, when set to 1, debug-related output is produced


	Notes
	-----
	Search rules

	Following search rules apply to all fields, exceptions noted below:
		searches are case-insensitive
		separators are comma or space
		when separators are present, white space between search terms is excluded
		quotation marks are used to search on a phrase, whitespaces are part of the phrase
		all search terms must be at least three characters

		If a single field is searched, datasets match on any search term appearing in any part in that field
		If more than one field is searched, datasets must have at least one match in each field being searched

		Asterisks in the input constrain the search
		Asterisk at the beginning {*abc} matching datasets have search fields that end in abc.
		Asterisk at the end {abc*}	matching datasets have search fields that begin with abc.
		Asterisk in the middle {ab*cd} matching datasets have search fields that begin with ab and end with cd.

		Single asterisk is treated as empty search, will return all data for field being searched.


	Exceptions
		@pHeaderID			quotation marks not supported, three character limit not enforced
		@pStartTime			only supports valid datetime values
		@pEndTime			only supports valid datetime values

		@pIncludeErrors		wildcards not supported
		@pIncludeIgnored	wildcards not supported

		@pTags				only integers supported
							no wildcard processing

	Revision
	--------
	carsoc3		2018-02-01		alpha release
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS

SET NOCOUNT, XACT_ABORT ON ;

 DECLARE	@p1					sql_variant
		  , @p2					sql_variant
		  , @p3					sql_variant
		  , @p4					sql_variant
		  , @p5					sql_variant
		  , @p6					sql_variant

		  , @pInputParameters	nvarchar(4000)
			;

  SELECT	@pInputParameters	=	(
										SELECT	[usp_GetResultsByTag.@pHeaderID]		=	@pHeaderID
											  , [usp_GetResultsByTag.@pTestName]		=	@pTestName
											  , [usp_GetResultsByTag.@pStartTime]		=	@pStartTime
											  , [usp_GetResultsByTag.@pEndTime]			=	@pEndTime
											  , [usp_GetResultsByTag.@pIncludeErrors]	=	@pIncludeErrors
											  , [usp_GetResultsByTag.@pIncludeIgnored]	=	@pIncludeIgnored
											  , [usp_GetResultsByTag.@pTags]			=	@pTags
											  , [usp_GetResultsByTag.@pSearchTerms]		=	@pSearchTerms
											  , [usp_GetResultsByTag.@pDebug]			=	@pDebug

												FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
									)
			;

BEGIN TRY


	 DECLARE	@delimiter		char(01)		=	CHAR(96)
			  , @TagTypeID		int
			  , @lHeaderID		nvarchar(max)
			  , @lTestName		nvarchar(max)
			  , @lSearchTerms	nvarchar(max)
			  , @lAssetNumbers	nvarchar(max)
			  , @pDataID		int				=	TRY_CONVERT( int, @pHeaderID )
				;


--	1)	Validate and scrub input data
	--	DatasetID:	no quoted phrases, numerics only except for * as wildcard
	 EXECUTE	hwt.usp_ScrubSearchInput
					@pSearchField	=	N'DatasetID'
				  , @pSearchInput	=	@pHeaderID
				  , @pSearchOutput	=	@lHeaderID OUTPUT
					;


	--	TestName:	minimum three character search limit.
	 EXECUTE	hwt.usp_ScrubSearchInput
					@pSearchField	=	N'TestName'
				  , @pSearchInput	=	@pTestName
				  , @pSearchOutput	=	@lTestName OUTPUT
					;

	--	SearchTerms:	minimum three character search limit.
	 EXECUTE	hwt.usp_ScrubSearchInput
					@pSearchField	=	N'SearchTerms'
				  , @pSearchInput	=	@pSearchTerms
				  , @pSearchOutput	=	@lSearchTerms OUTPUT
					;


	--	StartTime must be less than EndTime
	IF	( @pStartTime > @pEndTime )
		BEGIN
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'StartDate of %1 is after EndDate of %2'
						  , @p1			=	@pStartTime
						  , @p2			=	@pEndTime
						  , @p3			=	@pInputParameters
							;
		END


	--	Load Dataset IDs from input into temp storage
	DROP TABLE IF EXISTS #inputHeaderIDs ;

	  SELECT	HeaderID =	LTRIM( RTRIM( x.Item ) )
		INTO	#inputHeaderIDs
		FROM	utility.ufn_SplitString( @lHeaderID, @delimiter ) AS x
				;


	--	Define set of datasets to be searched
	--		default is all datasets unless data exists in #inputHeaderIDs
	DROP TABLE IF EXISTS #HeaderIDs ;

	  SELECT	HeaderID			=	h.HeaderID
			  , IncludeInResults	=	CONVERT( int, 1 )
		INTO	#HeaderIDs
		FROM	hwt.Header AS h
				INNER JOIN #inputHeaderIDs AS i
						ON h.HeaderIDStr LIKE i.HeaderID
							OR ISNULL( NULLIF( @lHeaderID, @delimiter ), '' ) = ''
				;


	--	Exclude HeaderIDs where StartTime is outside date parameters
	--	Add 1 day to @pEndTime to account for results generated during the day specified by @pEndTime
	  SELECT	@pStartTime =	ISNULL( @pStartTime, CONVERT( datetime, '1900-01-01' ) )
			  , @pEndTime	=	DATEADD( day, 1, ISNULL( @pEndTime, CONVERT( datetime, '2099-01-01' ) ) )
				;

	  UPDATE	tmp
		 SET	IncludeInResults = 0
		FROM	#HeaderIDs AS tmp
				INNER JOIN hwt.Header AS hdr
					ON hdr.HeaderID = tmp.HeaderID
	   WHERE	hdr.StartTime NOT BETWEEN @pStartTime AND @pEndTime
				;


	--	Drop Headers that do not match TestName search criteria
	DROP TABLE IF EXISTS #inputTestNames ;

	  SELECT	TestName =	LTRIM( RTRIM( x.Item ) )
		INTO	#inputTestNames
		FROM	utility.ufn_SplitString( @lTestName, @delimiter) AS x
				;

		WITH	headers AS
				(
				  SELECT	h.HeaderID
					FROM	hwt.Header AS h
							INNER JOIN #inputTestNames AS i
									ON h.TestName LIKE i.TestName
										OR @pTestName IS NULL
				)
	  UPDATE	tmp
		 SET	IncludeInResults = 0
		FROM	#HeaderIDs AS tmp
	   WHERE	NOT EXISTS( SELECT 1 FROM headers AS h WHERE h.HeaderID	 = tmp.HeaderID )
				;


	--	Drop Headers with errors when they are not included
	  UPDATE	tmp
		 SET	IncludeInResults = 0
		FROM	#HeaderIDs AS tmp
				INNER JOIN hwt.Vector AS v
					ON v.HeaderID = tmp.HeaderID

				INNER JOIN hwt.VectorError AS e
					ON e.VectorID = v.VectorID
	   WHERE	@pIncludeErrors = 0
				;


	--	Drop Headers that should be ignored
	  UPDATE	tmp
		 SET	IncludeInResults = 0
		FROM	#HeaderIDs AS tmp
				INNER JOIN	hwt.HeaderTag AS hTag
					ON hTag.HeaderID = tmp.HeaderID
						AND hTag.TagID = ( SELECT TagID FROM hwt.Tag WHERE Name = 'Ignore' )
	   WHERE	@pIncludeIgnored = 0
				;


	--	iterate over each tag type
	--	if there are any tags for a given tag type, drop headers that do not match tagID
	--	if there are no tags for a given tag type, do not drop any headers
	--	Load header data into temp storage
	DROP TABLE IF EXISTS #Tags ;

	  SELECT	TagTypeID	=	t.TagTypeID
			  , TagID		=	t.TagID
		INTO	#Tags
		FROM	hwt.Tag AS t
	   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pTags, '|' ) AS x
				   WHERE	CONVERT( int, x.Item ) = t.TagID
				)
				;

	WHILE EXISTS( SELECT 1 FROM #Tags )
		BEGIN
			  SELECT	TOP 1
						@TagTypeID	= TagTypeID
				FROM	#Tags
			ORDER BY	TagTypeID
						;

				WITH	cte AS
						(
						  SELECT	DISTINCT
									HeaderID
							FROM	hwt.HeaderTag AS hTag
									INNER JOIN #Tags AS t
											ON t.TagID = hTag.TagID
						   WHERE	t.TagTypeID = @TagTypeID
						)
			  UPDATE	tmp
				 SET	IncludeInResults = 0
				FROM	#HeaderIDs AS tmp
			   WHERE	tmp.HeaderID NOT IN ( SELECT cte.HeaderID FROM cte )
						;

			  DELETE	#Tags
			   WHERE	TagTypeID = @TagTypeID
						;

		END


	--	Drop headers where search terms do not match
	IF ( @lSearchTerms IS NOT NULL )
		BEGIN

			DROP TABLE IF EXISTS #SearchTerms ;
			DROP TABLE IF EXISTS #MatchingSearch ;

			  SELECT	SearchItem = Item
				INTO	#SearchTerms
				FROM	utility.ufn_SplitString( @lSearchTerms, @delimiter ) AS x
						;

			  SELECT	tmp.HeaderID
				INTO	#MatchingSearch
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.Header AS h
								ON h.HeaderID = tmp.HeaderID

						INNER JOIN #SearchTerms AS t
								ON h.Comments LIKE t.SearchItem
									OR h.HeaderIDStr		LIKE t.SearchItem
									OR h.ExternalFileInfo	LIKE t.SearchItem
									OR h.TestStationName	LIKE t.SearchItem
									OR h.TestName			LIKE t.SearchItem
									OR h.TestConfigFile		LIKE t.SearchItem
									OR h.TestCodePath		LIKE t.SearchItem
									OR h.TestCodeRevision	LIKE t.SearchItem
									OR h.HWTSysCodeRevision LIKE t.SearchItem
									OR h.KdrivePath			LIKE t.SearchItem
									OR h.ResultFileName		LIKE t.SearchItem
						;


			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.HeaderAppConst AS h
								ON h.HeaderID = tmp.HeaderID

						INNER JOIN hwt.AppConst AS ac
								ON ac.AppConstID = h.AppConstID

						INNER JOIN #SearchTerms AS t
								ON ac.Name LIKE t.SearchItem
									OR h.AppConstValue LIKE t.SearchItem
						;

			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.HeaderOption AS h
								ON h.HeaderID = tmp.HeaderID

						INNER JOIN hwt.[Option] AS o
								ON o.OptionID = h.OptionID

						INNER JOIN #SearchTerms AS t
								ON o.Name LIKE t.SearchItem
									OR h.OptionValue LIKE t.SearchItem
						;


			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.HeaderEquipment AS h
								ON h.HeaderID = tmp.HeaderID
						INNER JOIN hwt.Equipment AS e
								ON e.EquipmentID = h.EquipmentID
						INNER JOIN #SearchTerms AS t
								ON e.Asset LIKE t.SearchItem
									OR e.Description LIKE t.SearchItem
									OR e.CostCenter LIKE t.SearchItem
						;

			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.HeaderLibraryFile AS h
								ON h.HeaderID = tmp.HeaderID
						INNER JOIN hwt.LibraryFile AS lf
								ON lf.LibraryFileID = h.LibraryFileID
						INNER JOIN #SearchTerms AS t
								ON lf.FileName LIKE t.SearchItem
									OR lf.FileRev LIKE t.SearchItem
						;

			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.HeaderTag AS h
								ON h.HeaderID = tmp.HeaderID
						INNER JOIN hwt.Tag AS tag
								ON tag.TagID = h.TagID
						INNER JOIN #SearchTerms AS t
								ON tag.Name LIKE t.SearchItem
						;

			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.Vector AS v
								ON v.HeaderID = tmp.HeaderID
						INNER JOIN hwt.VectorElement AS ve
								ON ve.VectorID = v.VectorID
						INNER JOIN hwt.Element AS e
								ON e.ElementID = ve.ElementID
						INNER JOIN #SearchTerms AS t
								ON e.Name LIKE t.SearchItem
										OR ve.ElementValue	LIKE t.SearchItem
						;

			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.Vector AS v
								ON v.HeaderID = tmp.HeaderID
						INNER JOIN hwt.VectorResult AS vr
								ON vr.VectorID = v.VectorID
						INNER JOIN hwt.Result AS r
								ON r.ResultID = vr.ResultID
						INNER JOIN #SearchTerms AS t
								ON r.Name LIKE t.SearchItem
						;

			  INSERT	INTO #MatchingSearch
			  SELECT	tmp.HeaderID
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.Vector AS v
								ON v.HeaderID = tmp.HeaderID
						INNER JOIN hwt.VectorError AS e
								ON e.VectorID = v.VectorID
						INNER JOIN #SearchTerms AS t
								ON e.ErrorCode LIKE t.SearchItem
									OR e.ErrorText LIKE t.SearchItem
						;

			  UPDATE	tmp
				 SET	IncludeInResults = 0
				FROM	#HeaderIDs AS tmp
			   WHERE	tmp.HeaderID NOT IN ( SELECT HeaderID FROM #MatchingSearch )
						;

		END
		--	Drop headers where search terms do not match
	IF ( PATINDEX( '%[-]%', @pTags ) > 0 )
		BEGIN

			DROP TABLE IF EXISTS #AssetNumbers ;
			DROP TABLE IF EXISTS #MatchingAssets ;

			  SELECT	SearchItem	=	e.Asset
				INTO	#AssetNumbers
				FROM	hwt.Equipment AS e
						INNER JOIN utility.ufn_SplitString( @pTags, '|' ) AS x
								ON ABS( x.Item ) = e.EquipmentID
						;

			  SELECT	DISTINCT
						tmp.HeaderID
				INTO	#MatchingAssets
				FROM	#HeaderIDs AS tmp
						INNER JOIN hwt.HeaderEquipment AS he
								ON he.HeaderID = tmp.HeaderID

						INNER JOIN hwt.Equipment AS e
								ON e.EquipmentID = he.EquipmentID

						INNER JOIN #AssetNumbers AS t
								ON e.Asset = t.SearchItem
						;

			  UPDATE	tmp
				 SET	IncludeInResults = 0
				FROM	#HeaderIDs AS tmp
			   WHERE	tmp.HeaderID NOT IN ( SELECT HeaderID FROM #MatchingAssets )
						;

		END

	--	Output results
	  SELECT	DatasetID
			  , InProgress
			  , Project
			  , TestName
			  , TestMode
			  , Operator
			  , StartTime
			  , EndTime
			  , TestDuration
			  , TestStationID
			  , FWRevision
			  , HWIncrement
			  , Tags
			  , TestProcedureNum
			  , Requirements
			  , DeviceModel
			  , DataStatus
			  , DUTType
			  , FunctionBlock
			  , DeviceSN
			  , Error
			  , Ignored
			  , Comments
			  , ErrorText
			  , Assets
		FROM	hwt.vw_SearchResults AS r
	   WHERE	r.DatasetID IN ( SELECT HeaderID FROM #HeaderIDs WHERE IncludeInResults = 1 )
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