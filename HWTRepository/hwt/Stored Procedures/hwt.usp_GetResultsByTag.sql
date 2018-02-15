CREATE PROCEDURE 
	hwt.usp_GetResultsByTag( 
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

    Procedure:  hwt.usp_GetResultsByTag
    Abstract:   Given a set of search parameters, return datasets that match search parameters

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE test options from temp storage into hwt.Option
    3)  MERGE header test options from temp storage into hwt.HeaderOption

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
	@pDebug				int				Used for debugging, when set to 1, debug-related output is produced
	
	
    Notes
    -----
	Search rules 
	Datasets are *excluded* from search based on absence of specific criteria
		@pHeaderID
			If NULL, Empty, or a single wildcard '*', return all headers
			If data is specified without wildcard, return only the headerID specified
			If data with wildcard is used, return all datasets that match the wildcard

		@pTestName			
			If NULL, Empty, or a single wildcard '*', return all headers
			If data is specified without wildcard, return only the headerID specified
			If data with wildcard is used, return all datasets that match the wildcard
			
		@pStartTime
			If NULL, returns all datasets 
			If NOT NULL, returns all datasets that start after specified time 
			
		@pEndTime			datetime		Specifies latest Start Date for test 
			If NULL, returns all datasets 
			If NOT NULL, returns all datasets that start before specified time 
			
		@pIncludeErrors		
			If NULL or 0, excludes any dataset that threw an error during testing 
			If set to 1, include datasets that threw an error during testing 
			
		@pIncludeIgnored	
			If NULL or 0, excludes any dataset where the Ignored tag is present 
			If set to 1, includes datasets where the Ignore tag has been applied 
			
		@pTags				
			If NULL or empty, returns all datasets 
			If one or more tagIDs are present:
				Process tags by TagType:
					If there are no TagIDs specified for a given TagType, include all datasets
					Within a given TagType, include only datasets that match the specified tags
					Datasets are OR'd for inclusion within a given tag type 
					Datasets are AND'd for inclusion between multiple tag types
		
		@pSearchTerms		
			If NULL or empty, return all datasets 
			If one or more search terms are present:
				Return all datasets that contain any fragment of any search terms 
				Search terms are OR'd together

    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS
	
SET XACT_ABORT, NOCOUNT ON ; 

BEGIN TRY

	DECLARE 
		@ErrorMessage	nvarchar(max) = NULL 
	  , @TagTypeID		int 
	; 


	--	Load HeaderIDs into temp storage
	--	Convert wildcard if present 
	DROP TABLE IF EXISTS #HeaderIDs ; 
	
	CREATE TABLE 
		#HeaderIDs( 
			HeaderID			int 
		  , IncludeInResults	tinyint		DEFAULT 1 
		)
	; 
	
	
	
	--	Convert input @pHeaderID for wildcards 
	SELECT 
		@pHeaderID 	=	CASE
							WHEN @pHeaderID = '' THEN NULL
							WHEN CHARINDEX( '*', @pHeaderID ) > 0 THEN REPLACE( @pHeaderID, '*', '%' )
							WHEN ISNUMERIC( @pHeaderID ) = 1 THEN @pHeaderID
							ELSE @pHeaderID
						END
	;
	
	INSERT INTO 
		#HeaderIDs( HeaderID )
	SELECT 
		HeaderID
	FROM 
		hwt.Header 
	WHERE 
		( CHARINDEX( '%', @pHeaderID ) > 0 AND HeaderIDStr LIKE @pHeaderID )
			OR 
		( HeaderIDStr = ISNULL( @pHeaderID, HeaderIDStr ) ) 
	;
	

	--	Exclude HeaderIDs where StartTime is outside date parameters 
	SELECT 
		@pStartTime = 	ISNULL( @pStartTime, CONVERT( datetime, '1900-01-01' ) )
	  , @pEndTime	=	ISNULL( @pEndTime, CONVERT( datetime, '2099-01-01' ) )
	; 
	
	UPDATE 
		tmp
	SET 
		IncludeInResults = 0 
	FROM 
		#HeaderIDs AS tmp 
	INNER JOIN 
		hwt.Header AS hdr 
			ON hdr.HeaderID = tmp.HeaderID
	WHERE 
		hdr.StartTime NOT BETWEEN @pStartTime AND @pEndTime 
	; 
	

	--	Drop Headers that do not match TestName search criteria 
	SELECT 
		@pTestName 	=	CASE
							WHEN @pTestName = '' THEN NULL
							WHEN CHARINDEX( '*', @pTestName ) > 0 THEN REPLACE( @pTestName, '*', '%' )
							ELSE @pTestName
						END
	;	
	
	UPDATE 
		tmp
	SET 	
		IncludeInResults = 0 
	FROM
		#HeaderIDs AS tmp 
	INNER JOIN 
		hwt.Header AS hdr 
			ON hdr.HeaderID = tmp.HeaderID
	WHERE 
		@pTestName IS NOT NULL 
			AND hdr.TestName NOT LIKE @pTestName
	; 
		

	--	Drop Headers with errors when they are not included 
	UPDATE 
		tmp
	SET 	
		IncludeInResults = 0 
	FROM
		#HeaderIDs AS tmp
	INNER JOIN 
		hwt.Vector AS v 
			ON v.HeaderID = tmp.HeaderID
	INNER JOIN 
		hwt.TestError AS e 
			ON e.VectorID = v.VectorID 
	WHERE
		@pIncludeErrors = 0 ; 
		
	
	--	Drop Headers that should be ignored
	UPDATE 
		tmp
	SET 	
		IncludeInResults = 0 
	FROM
		#HeaderIDs AS tmp
	INNER JOIN 
		hwt.HeaderTag AS hTag
			ON hTag.HeaderID = tmp.HeaderID 
				AND hTag.TagID = ( SELECT TagID FROM hwt.Tag WHERE Name = 'Ignore' ) 
	WHERE
		@pIncludeIgnored = 0 ; 
		
	
	--	iterate over each tag type
	--	if there are any tags for a given tag type, drop headers that do not match tagID 
	--	if there are no tags for a given tag type, do not drop any headers 
	--	Load header data into temp storage
	IF OBJECT_ID( 'tempdb..#Tags') IS NOT NULL
		DROP TABLE #Tags ;

	SELECT 
		TagTypeID	=	t.TagTypeID 
	  , TagID		=	t.TagID 
	INTO
		#Tags
	FROM 
		hwt.Tag AS t 
	WHERE EXISTS( 
		SELECT 1 FROM utility.ufn_SplitString( @pTags, '|' ) AS x  
		WHERE CONVERT( int, x.Item ) = t.TagID ) ; 

	WHILE EXISTS( SELECT 1 FROM #Tags ) 
	BEGIN 
		
		SELECT TOP 1 @TagTypeID	= TagTypeID
		FROM #Tags ORDER BY TagTypeID ; 

		WITH 
			cte AS ( 
				SELECT DISTINCT  
					HeaderID 
				FROM 
					hwt.HeaderTag AS hTag 
				INNER JOIN 
					#Tags AS t 
						ON t.TagID = hTag.TagID
				WHERE t.TagTypeID = @TagTypeID ) 
		UPDATE 
			tmp
		SET 	
			IncludeInResults = 0 
		FROM
			#HeaderIDs AS tmp 
		WHERE 
			tmp.HeaderID NOT IN ( SELECT cte.HeaderID FROM cte ) ; 

		DELETE #Tags WHERE TagTypeID = @TagTypeID ;

	END
	; 
	
	--	Drop headers where search terms do not match	
	IF @pSearchTerms IS NOT NULL
	BEGIN 
		IF OBJECT_ID( 'tempdb..#SearchTerms' ) IS NOT NULL 
			DROP TABLE #SearchTerms
			
		SELECT 
			SearchItem	=	'%' + x.Item + '%'
		INTO 
			#SearchTerms
		FROM 
			utility.ufn_SplitString( @pSearchTerms, '|' ) AS x  
		WHERE 
			LEN( x.Item ) > 2 
		; 
		
		SELECT 
			tmp.HeaderID 
		INTO 
			#MatchingSearch 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.Header AS h 
				ON h.HeaderID = tmp.HeaderID 
		INNER JOIN 
			#SearchTerms AS t 
				ON( 
					h.Comments LIKE t.SearchItem 
						OR h.HeaderIDStr		LIKE t.SearchItem
						OR h.ExternalFileInfo 	LIKE t.SearchItem 
						OR h.TestStationName	LIKE t.SearchItem 
						OR h.TestName           LIKE t.SearchItem  
						OR h.TestConfigFile     LIKE t.SearchItem  
						OR h.TestCodePath       LIKE t.SearchItem  
						OR h.TestCodeRevision   LIKE t.SearchItem  
						OR h.HWTSysCodeRevision LIKE t.SearchItem  
						OR h.KdrivePath         LIKE t.SearchItem   
						OR h.ResultFileName     LIKE t.SearchItem  
				)
		; 
		
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.HeaderAppConst AS h 
				ON h.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.AppConst AS ac 
				ON ac.AppConstID = h.AppConstID
		INNER JOIN 
			#SearchTerms AS t 
				ON ac.Name LIKE t.SearchItem 
					OR h.AppConstValue	LIKE t.SearchItem
		; 
		
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.HeaderOption AS h 
				ON h.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.[Option] AS o
				ON o.OptionID = h.OptionID
		INNER JOIN 
			#SearchTerms AS t 
				ON o.Name LIKE t.SearchItem 
					OR h.OptionValue	LIKE t.SearchItem
		; 
				
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.HeaderEquipment AS h 
				ON h.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.Equipment AS e 
				ON e.EquipmentID = h.EquipmentID
		INNER JOIN 
			#SearchTerms AS t 
				ON e.Asset LIKE t.SearchItem 
					OR e.Description 	LIKE t.SearchItem 
					OR e.CostCenter		LIKE t.SearchItem 
		; 	
		
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.HeaderLibraryFile AS h 
				ON h.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.LibraryFile AS lf
				ON lf.LibraryFileID = h.LibraryFileID
		INNER JOIN 
			#SearchTerms AS t 
				ON lf.FileName LIKE t.SearchItem 
					OR lf.FileRev	LIKE t.SearchItem 
		; 			
			
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.HeaderTag AS h 
				ON h.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.Tag AS tag
				ON tag.TagID = h.TagID
		INNER JOIN 
			#SearchTerms AS t 
				ON tag.Name LIKE t.SearchItem 
		; 	
			
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.Vector AS v
				ON v.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.VectorElement AS ve
				ON ve.VectorID = v.VectorID 
		INNER JOIN 
			hwt.Element AS e
				ON e.ElementID = ve.ElementID  
		INNER JOIN 
			#SearchTerms AS t 
				ON e.Name LIKE t.SearchItem 
					OR ve.ElementValue	LIKE t.SearchItem
		; 			
			
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.Vector AS v
				ON v.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.VectorResult AS vr
				ON vr.VectorID = v.VectorID 
		INNER JOIN 
			hwt.Result AS r
				ON r.ResultID = vr.ResultID  
		INNER JOIN 
			#SearchTerms AS t 
				ON r.Name LIKE t.SearchItem 
		; 			
					
		INSERT INTO 
			#MatchingSearch 
		SELECT 
			tmp.HeaderID 
		FROM 
			#HeaderIDs AS tmp 
		INNER JOIN 
			hwt.Vector AS v
				ON v.HeaderID = tmp.HeaderID 
		INNER JOIN 
			hwt.TestError AS e
				ON e.VectorID = v.VectorID 
		INNER JOIN 
			#SearchTerms AS t 
				ON e.ErrorCode LIKE t.SearchItem 
					OR e.ErrorText LIKE t.SearchItem
		; 	

		UPDATE 
			tmp
		SET 	
			IncludeInResults = 0 
		FROM
			#HeaderIDs AS tmp 
		WHERE 
			tmp.HeaderID NOT IN ( SELECT HeaderID FROM #MatchingSearch ) ; 		

	END
	
	--	Output results 
	SELECT	*
	FROM	hwt.vw_SearchResults AS r
	WHERE	r.TestNumber IN ( SELECT HeaderID FROM #HeaderIDs WHERE IncludeInResults = 1 ) 
	; 


	RETURN; 
END TRY

BEGIN CATCH
	PRINT 'Throwing Error' ; 
	IF @ErrorMessage IS NOT NULL
		THROW 60000, @ErrorMessage , 1; 
	ELSE 
		THROW ; 
END CATCH