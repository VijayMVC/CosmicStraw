CREATE PROCEDURE hwt.usp_LoadVectorFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadVectorFromStage
    Abstract:   Load changed vector data from stage to hwt.Vector

    Logic Summary
    -------------
	1)  INSERT data into temp storage from trigger
	2)  INSERT vector data from temp storage into hwt.Vector
	3)  Insert requirements tags from vector into temp storage
	4)  INSERT tags from temp storage into hwt.Tag
	5)	Load ReqID tags to hwt.VectorRequirement
	6)  INSERT ReqID tags into hwt.HeaderTag


    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-04-27		production release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    --  define temp storage tables
    IF  ( 1 = 0 )
        CREATE TABLE	#inserted
						(
							ID          	int
						  , HeaderID    	int
						  , VectorNum   	int
						  , Loop        	int
						  , ReqID       	nvarchar(1000)
						  , StartTime   	nvarchar(50)
						  , EndTime     	nvarchar(50)
						  , CreatedDate		datetime
						)
						;

    CREATE TABLE	#changes
					(
						ID              int
					  , HeaderID        int
					  , VectorNum       int
					  , Loop            int
					  , ReqID           nvarchar(1000)
					  , StartTime       nvarchar(50)
					  , EndTime         nvarchar(50)
					  , OperatorName    nvarchar(50)
					)
					;


--  1)  INSERT data into temp storage from trigger
      INSERT 	INTO #changes
					( ID, HeaderID, VectorNum, Loop, ReqID, StartTime , EndTime, OperatorName )
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


--  2)  INSERT vector data from temp storage into hwt.Vector
	  INSERT	hwt.Vector
					( VectorID, HeaderID, VectorNumber, LoopNumber, StartTime, EndTime, UpdatedBy, UpdatedDate )

	  SELECT	VectorID        =   tmp.ID
			  , HeaderID        =   tmp.HeaderID
			  , VectorNumber    =   tmp.VectorNum
			  , LoopNumber      =   tmp.Loop
			  , StartTime       =   CONVERT( datetime, tmp.StartTime, 109 )
			  , EndTime         =   NULLIF( CONVERT( datetime, tmp.EndTime, 109 ), '1900-01-01' )
			  , UpdatedBy       =   tmp.OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	#changes AS tmp
				;


--  3)  Insert requirements tags from vector into temp storage
    DROP TABLE IF EXISTS #tags ;

      SELECT	DISTINCT
			    VectorID 	= 	tmp.ID
			  , HeaderID    =   tmp.HeaderID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   LTRIM( RTRIM( x.Item ) )
			  , Description =   ''
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		INTO	#tags
		FROM	#changes AS tmp

				CROSS JOIN hwt.TagType AS tType

				OUTER APPLY utility.ufn_SplitString( tmp.ReqID, ',' ) AS x

	   WHERE 	tType.Name = 'ReqID'
					AND ISNULL( tmp.ReqID, '' ) != ''
				;

		
	--	Drop ReqID nodes with values of NA
      DELETE	FROM #tags
	   WHERE	Name IN ( N'NA', 'N/A' )
				;


--  4)  INSERT tags from temp storage into hwt.Tag
		WITH	newTags AS
				(
				  SELECT 	DISTINCT
							TagTypeID
						  , Name
						  , Description
					FROM 	#tags AS tmp
				   WHERE	NOT EXISTS
							(
							  SELECT  	1
								FROM    hwt.Tag AS tag
							   WHERE   	tag.TagTypeID = tmp.TagTypeID
											AND tag.Name = tmp.Name
							)
				)
      INSERT 	INTO hwt.Tag
					( TagTypeID, Name, Description, IsDeleted, UpdatedBy, UpdatedDate )
	  SELECT	TagTypeID
			  , Name
			  , Description
			  , IsDeleted   =   0
			  , UpdatedBy	=	tags.UpdatedBy
			  , UpdatedDate =   GETDATE()
		FROM	newTags AS nt
				CROSS APPLY
					(
						  SELECT	TOP 1
									UpdatedBy
							FROM 	#tags AS t
						   WHERE	t.TagTypeID = nt.TagTypeID
										AND t.Name = nt.Name
						ORDER BY	t.HeaderID
					) AS tags
					;

    --  Apply new TagID back into temp storage
      UPDATE	tmp
		 SET	TagID   =   tag.TagID
		FROM	#tags AS tmp
				INNER JOIN hwt.Tag AS tag
						ON tag.TagTypeID = tmp.TagTypeID
							AND tag.Name = tmp.Name
				;

--	5)	Load ReqID tags to hwt.VectorRequirement
	  INSERT	hwt.VectorRequirement
					( VectorID, TagID, UpdatedBy, UpdatedDate )

	  SELECT	DISTINCT
				VectorID	=	VectorID
			  , TagID		=	TagID
			  , UpdatedBy	=	UpdatedBy
			  , UpdatedDate	=	GETDATE()
		FROM 	#tags 
				;



--  6)  INSERT ReqID tags into hwt.HeaderTag
	DECLARE 	@HeaderID		int ;
	DECLARE 	@TagID			nvarchar(max) ;
	DECLARE		@OperatorName	sysname ;
				;

	WHILE EXISTS ( SELECT 1 FROM #tags )
		BEGIN

			  SELECT 	DISTINCT
						@HeaderID 		=	HeaderID
					  , @OperatorName	=	UpdatedBy
				FROM 	#tags
						;

			  SELECT	@TagID 		=	STUFF
										(
											(
											  SELECT 	DISTINCT
														N'|' + CONVERT( nvarchar(20), t.TagID )
												FROM 	#tags AS t
											   WHERE 	t.HeaderID = @HeaderID
														AND NOT EXISTS
															(
															  SELECT 	1 FROM hwt.HeaderTag AS ht
															   WHERE 	ht.HeaderID = @HeaderID
																			AND ht.TagID = t.TagID
															)
														FOR XML PATH (''), TYPE
											).value('.', 'nvarchar(max)'), 1, 1, ''
										)
						;

			IF	@TagID != ''
				BEGIN
					 EXECUTE 	hwt.usp_AssignTagsToDatasets
									@pUserID	= @OperatorName
								  , @pHeaderID	= @HeaderID
								  , @pTagID		= @TagID
								  , @pNotes		= 'Tag assigned during vector load.'
								;
				END

			  DELETE	#tags
			   WHERE	HeaderID = @HeaderID
						AND UpdatedBy = @OperatorName
						;
		END


    	RETURN 0 ;

END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 )
		ROLLBACK TRANSACTION ;

	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ;

	RETURN 55555 ;

END CATCH