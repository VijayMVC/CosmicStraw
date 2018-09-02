CREATE PROCEDURE
	hwt.usp_LoadVectorFromStage
		(
			@pInsertXML		xml
		)
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

	 DECLARE	@requirement	TABLE	(
											VectorID		int
										  , HeaderID		int
										  , NodeOrder		int
										  , TagName			nvarchar(50)
										  , UpdatedBy		sysname
										  , TagExists		tinyint			DEFAULT 0
										  , TagID			int
										)
				;

	 DECLARE	@inserted		TABLE	(
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
	  INSERT	@inserted
					( ID, HeaderID, VectorNum, Loop, ReqID, StartTime, EndTime, OperatorName )
	  SELECT	ID					=	i.xmlData.value( 'ID[1]'		, 'int' )
			  , HeaderID			=	i.xmlData.value( 'HeaderID[1]'	, 'int' )
			  , VectorNum			=	i.xmlData.value( 'VectorNum[1]'	, 'int' )
			  , Loop				=	i.xmlData.value( 'Loop[1]'		, 'int' )
			  , ReqID				=	i.xmlData.value( 'ReqID[1]'		, 'nvarchar(1000)' )
			  , StartTime			=	i.xmlData.value( 'StartTime[1]'	, 'nvarchar(50)' )
			  , EndTime				=	i.xmlData.value( 'EndTime[1]'	, 'nvarchar(50)' )
			  , OperatorName	  =	h.OperatorName
		FROM	@pInsertXML.nodes('trg_vector/inserted') AS i(xmlData)
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.xmlData.value( 'HeaderID[1]'	, 'int' )
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
		FROM	@inserted AS tmp
				;


--	4)	Insert requirements tags from vector into temp storage
	  INSERT	@requirement
					( VectorID, HeaderID, NodeOrder, TagName, UpdatedBy )
	  SELECT	VectorID		=	tmp.ID
			  , HeaderID		=	tmp.HeaderID
			  , NodeOrder		=	x.ItemNumber
			  , Name			=	LTRIM( RTRIM( x.Item ) )
			  , UpdatedBy		=	tmp.OperatorName
		FROM	@inserted AS tmp
				OUTER APPLY utility.ufn_SplitString( tmp.ReqID, ',' ) AS x
	   WHERE	ISNULL( tmp.ReqID, '' ) != ''
					AND LTRIM( RTRIM( x.Item ) ) NOT IN( N'NA', N'N/A' )
				;

	IF	( @@ROWCOUNT != 0 )
	BEGIN

--	5)	Find requirement tags that already exist
		 DECLARE	@tagTypeID	int ;

		  SELECT	@tagTypeID	=	TagTypeID
			FROM	hwt.TagType
		   WHERE	Name = N'ReqID'
					;

		  UPDATE	r
			 SET	TagExists	=	1
			FROM	@requirement AS r
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	hwt.Tag AS t
						   WHERE	t.TagTypeID =	@TagTypeID
										AND t.Name = r.TagName
						)
					;

		  INSERT	INTO hwt.Tag
						( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate )
		  SELECT	DISTINCT
					@TagTypeID
				  , r.TagName
				  , Description		=	'Requirement extracted from vector'
				  , IsDeleted		=	0
				  , UpdatedBy		=	FIRST_VALUE( r.UpdatedBy ) OVER( PARTITION BY TagName ORDER BY HeaderID )
				  , UpdatedDate		=	SYSDATETIME()
			FROM	@requirement AS r
		   WHERE	r.TagExists = 0
					;

		--	Apply new TagID back into temp storage
		  UPDATE	r
			 SET	TagID	=	tag.TagID
			FROM	@requirement AS r
					INNER JOIN	hwt.Tag AS tag
							ON	tag.TagTypeID = @TagTypeID
								AND tag.Name = r.TagName
					;

--	6)	Load ReqID tags to hwt.VectorRequirement
		  INSERT	hwt.VectorRequirement
						( VectorID, TagID, NodeOrder )

		  SELECT	DISTINCT
					VectorID	=	VectorID
				  , TagID		=	TagID
				  , NodeOrder	=	NodeOrder
			FROM	@requirement
					;


--	7)	INSERT ReqID tags into hwt.HeaderTag
		 DECLARE	@pHeaderID		nvarchar(max)
				  , @pTagID			nvarchar(max)
				  , @pOperatorName	sysname
					;

		 DECLARE	cursorTags
		  CURSOR	LOCAL FORWARD_ONLY STATIC READ_ONLY
			 FOR	  SELECT	HeaderID		=	CONVERT( nvarchar(20), HeaderID )
							  , OperatorName	=	UpdatedBy
							  , TagId			=	STUFF
														(
															(
															  SELECT	DISTINCT
																		'|' + CONVERT( nvarchar(20), TagID )
																FROM	@requirement AS a
															   WHERE	a.HeaderID = b.HeaderID
																			AND NOT EXISTS	(
																							  SELECT	1
																								FROM	hwt.HeaderTag AS ht
																							   WHERE	ht.HeaderID = a.HeaderID
																											AND ht.TagID = a.TagID
																							)

																		FOR XML PATH(''), TYPE
															).value( '.', 'nvarchar(max) ' ), 1, 1, ''
														)
						FROM	@requirement AS b
					GROUP BY	HeaderID, UpdatedBy
					;

			OPEN	cursorTags ;

			WHILE ( 1 = 1 )
			BEGIN

				   FETCH	cursorTags
					INTO	@pHeaderID, @pOperatorName, @pTagID ;

					IF	( @@FETCH_STATUS != 0 ) BREAK ;

					IF	( @pTagID != N'' )
						EXECUTE	hwt.usp_AssignTagsToDatasets
								@pUserID	= @pOperatorName
							  , @pHeaderID	= @pHeaderID
							  , @pTagID		= @pTagID
							  , @pNotes		= 'Tag assigned during vector load.'
							;
			END

			CLOSE cursorTags ;
			DEALLOCATE cursorTags ;

	END

--	1)	INSERT notification into labViewStage.LoadHWTAudit that the header needs to be processed
	  INSERT	labViewStage.LoadHWTVector
	  SELECT	ID
		FROM	@inserted
				;

	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	( SELECT	@pInsertXML )
										  , (
											  SELECT	*
												FROM	@inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
										  , (
											  SELECT	*
												FROM	@requirement
														FOR XML PATH( 'requirement' ), TYPE, ELEMENTS XSINIL
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