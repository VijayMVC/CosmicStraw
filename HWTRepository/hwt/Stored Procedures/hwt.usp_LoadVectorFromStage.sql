CREATE PROCEDURE 
	hwt.usp_LoadVectorFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadVectorFromStage
	Abstract:	Load changed vector data from stage to hwt.Vector

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT data into temp storage from labViewStage
	3)	INSERT vector data from temp storage into hwt.Vector
	4)	Insert requirements tags from vector into temp storage
	5)	INSERT tags from temp storage into hwt.Tag
	6)	Load ReqID tags to hwt.VectorRequirement
	7)	INSERT ReqID tags into hwt.HeaderTag
	8)	UPDATE PublishDate on labViewStage.vector
	9)	EXECUTE sp_releaseapplock to release lock


	Parameters
	----------

	Notes
	-----

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
		CREATE TABLE 
			#inserted
				(
					ID				int
				  , HeaderID		int
				  , VectorNum		int
				  , Loop			int
				  , ReqID			nvarchar(1000)
				  , StartTime		nvarchar(50)
				  , EndTime			nvarchar(50)
				  , CreatedDate		datetime2(3)
				)
			;


	CREATE TABLE 
		#changes
			(
				ID				int
			  , HeaderID		int
			  , VectorNum		int
			  , Loop			int
			  , ReqID			nvarchar(1000)
			  , StartTime		nvarchar(50)
			  , EndTime			nvarchar(50)
			  , OperatorName	nvarchar(50)
			)
		;


--	1)	INSERT data from trigger temp storage into temp storage
	  INSERT	INTO #changes
					( ID, HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime, OperatorName )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.VectorNum
			  , i.Loop
			  , i.ReqID
			  , i.StartTime
			  , i.EndTime
			  , h.OperatorName
		FROM	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID
				;


--	3)	INSERT vector data from temp storage into hwt.Vector
	  INSERT	hwt.Vector
					( VectorID, HeaderID, VectorNumber, LoopNumber, StartTime, EndTime, CreatedDate )

	  SELECT	VectorID		=	tmp.ID
			  , HeaderID		=	tmp.HeaderID
			  , VectorNumber	=	tmp.VectorNum
			  , LoopNumber		=	tmp.Loop
			  , StartTime		=	CONVERT( datetime2(3), tmp.StartTime )
			  , EndTime			=	NULLIF( CONVERT( datetime2(3), tmp.EndTime ), '1900-01-01' )
			  , CreatedDate		=	SYSDATETIME()
		FROM	#changes AS tmp
				;


--	4)	Insert requirements tags from vector into temp storage
	DROP TABLE IF EXISTS #tags ;
	  SELECT	VectorID	=	tmp.ID
			  , HeaderID	=	tmp.HeaderID
			  , TagTypeID	=	tType.TagTypeID
			  , NodeOrder	=	x.ItemNumber
			  , Name		=	LTRIM( RTRIM( x.Item ) )
			  , UpdatedBy	=	tmp.OperatorName
			  , TagID		=	CONVERT( int, NULL )
		INTO	#tags
		FROM	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType

				OUTER APPLY utility.ufn_SplitString( tmp.ReqID, ',' ) AS x
	   WHERE	tType.Name = 'ReqID'
					AND ISNULL( tmp.ReqID, '' ) != ''
					AND LTRIM( RTRIM( x.Item ) ) NOT IN( N'NA', N'N/A' )
				;


--	5)	INSERT tags from temp storage into hwt.Tag
		WITH	newTags AS
				(
				  SELECT	TagTypeID
						  , Name
					FROM	#tags AS tmp

				  EXCEPT
				  SELECT	TagTypeID
						  , Name
					FROM	hwt.Tag AS tag
				)
	  INSERT	INTO hwt.Tag
					( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate )
	  SELECT	nt.TagTypeID
			  , nt.Name
			  , Description	=	'Requirement extracted from vector'
			  , IsDeleted	=	0
			  , UpdatedBy	=	tags.UpdatedBy
			  , UpdatedDate =	SYSDATETIME()
		FROM	newTags AS nt
				CROSS APPLY
					(
						  SELECT	TOP 1
									UpdatedBy
							FROM	#tags AS t
						   WHERE	t.TagTypeID = nt.TagTypeID
										AND t.Name = nt.Name
						ORDER BY	t.HeaderID
					) AS tags
				;

	--	Apply new TagID back into temp storage
	  UPDATE	tmp
		 SET	TagID	=	tag.TagID
		FROM	#tags AS tmp
				INNER JOIN 	hwt.Tag AS tag
						ON 	tag.TagTypeID = tmp.TagTypeID
							AND tag.Name = tmp.Name
				;

--	6)	Load ReqID tags to hwt.VectorRequirement
	  INSERT	hwt.VectorRequirement
					( VectorID, TagID, NodeOrder )

	  SELECT	DISTINCT
				VectorID	=	VectorID
			  , TagID		=	TagID
			  , NodeOrder	=	NodeOrder
		FROM	#tags
				;



--	7)	INSERT ReqID tags into hwt.HeaderTag
	DECLARE		@HeaderID		int ;
	DECLARE		@TagID			nvarchar(max) ;
	DECLARE		@OperatorName	sysname ;
				;

	WHILE EXISTS ( SELECT 1 FROM #tags )
	BEGIN

		  SELECT	TOP 1
					@HeaderID		=	HeaderID
				  , @OperatorName	=	UpdatedBy
			FROM	#tags
					;

		  SELECT	@TagID		=	STUFF(
											(
											  SELECT	DISTINCT
														N'|' + CONVERT( nvarchar(20), t.TagID )
												FROM	#tags AS t
											   WHERE	t.HeaderID = @HeaderID
														AND NOT EXISTS
															(
															  SELECT	1 FROM hwt.HeaderTag AS ht
															   WHERE	ht.HeaderID = @HeaderID
																			AND ht.TagID = t.TagID
															)
														FOR XML PATH (''), TYPE
											).value('.', 'nvarchar(max)'), 1, 1, ''
										 )
					;

		IF	NOT ( @TagID = '' )
			EXECUTE	hwt.usp_AssignTagsToDatasets
						@pUserID	= @OperatorName
					  , @pHeaderID	= @HeaderID
					  , @pTagID		= @TagID
					  , @pNotes		= 'Tag assigned during vector load.'
					;

		  DELETE	#tags
		   WHERE	HeaderID = @HeaderID
					;
	END


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
											FOR XML PATH( 'usp_LoadVectorFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

	RETURN 55555 ;

END CATCH