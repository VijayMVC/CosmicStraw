CREATE PROCEDURE hwt.usp_GetTagsByHeader
	( 
		@pHeaderID	nvarchar(max)
	)
/*
***********************************************************************************************************************************

  Procedure:	hwt.usp_GetTagsByHeader
   Abstract:  	return all tags for a given DatasetID 
	
	
    Logic Summary
    -------------

    Parameters
    ----------
	@pHeaderID		nvarchar(max)	pipe-delimited set of DatasetIDs, dataset IDs must be numeric
	 
    Notes
    -----

    Revision
    --------
    carsoc3     2018-4-27		Production release 
	
***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ; 

BEGIN TRY

--	1)	Validate input 
	IF  ( @pHeaderID IS NULL ) 
	BEGIN
		--	@pHeaderID must not be NULL 
		 EXECUTE	eLog.log_ProcessEventLog 	@pProcID	=	@@PROCID
											  , @pMessage	=	N'Error: @pHeaderID must not be NULL' ; 
	END

	IF	( PATINDEX( '%[^ 0-9|]%', @pHeaderID ) > 0 )
	BEGIN
		--	@pHeaderID must contain only numerics, spaces and the pipe-delimiter {|} 
		 EXECUTE	eLog.log_ProcessEventLog 	@pProcID	=	@@PROCID
											  , @pMessage	=	N'Error: @pHeaderID contains invalid input.  @pHeaderID: %1' 
											  , @p1			=	@pHeaderID ; 
	END
	

--	2)	INSERT tags for requested datasets into temp storage	
	DROP TABLE IF EXISTS #tags ; 

	  SELECT 	DISTINCT 
				HeaderID	=	CONVERT( int, x.Item ) 
	          , TagTypeID	=	tType.TagTypeID 
	          , TagTypeName	=	tType.Name 
	          , Tags		=	CONVERT( nvarchar(max), NULL ) 
		INTO 	#tags
		FROM 	utility.ufn_SplitString( @pHeaderID, '|' ) AS x 
				INNER JOIN hwt.HeaderTag AS hTag
						ON hTag.HeaderID = CONVERT( int, x.Item )
						
				INNER JOIN hwt.Tag AS t 
						ON t.TagID = hTag.TagID 
						
				INNER JOIN hwt.TagType AS tType 
						ON tType.TagTypeID = t.TagTypeID ; 

--	3)	For each tag type, return set of tags as a pipe-delimited list 						
	  UPDATE	tmp 
		 SET 	Tags	=	STUFF
							(
								( 
								  SELECT	'|' + t.Name 
									FROM	hwt.Tag AS t 
											INNER JOIN hwt.TagType AS tt 
													ON tt.TagTypeID = t.TagTypeID 
							
											INNER JOIN hwt.HeaderTag ht 
													ON ht.TagID = t.TagID 
								   WHERE 	ht.HeaderID = tmp.HeaderID 
												AND tt.TagTypeID = tmp.TagTypeID
								ORDER BY 	t.Name
											FOR XML PATH( '' ), TYPE 
								).value( '.', 'nvarchar(max)' ), 1, 1, '' 
							)
		FROM 	#tags AS tmp ;

	  SELECT * FROM #tags ; 
	
	  RETURN 0 ; 

END TRY
BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) 
		ROLLBACK TRANSACTION ; 
	
	  EXECUTE	eLog.log_CatchProcessing	@pProcID = @@PROCID ; 
	
	RETURN 55555 ; 

END CATCH	
