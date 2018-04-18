CREATE PROCEDURE hwt.usp_LoadVectorFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadVectorFromStage
    Abstract:   Load changed vector data from stage to hwt.Vector

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  DELETE vector records that are unchanged from temp storage
    3)  MERGE vector changes from temp storage into hwt.Vector
    4)  INSERT tags from temp storage into hwt.Tag
    5)  MERGE new header tag data into hwt.HeaderTag

    Parameters
    ----------

    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

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
          , HWTChecksum     int
        ) 
		;


--  1)  INSERT data into temp storage from trigger
      INSERT 	INTO #changes
					( ID, HeaderID, VectorNum, Loop, ReqID, StartTime , EndTime, OperatorName, HWTChecksum )
	  SELECT	i.ID          		
              , i.HeaderID    		
              , i.VectorNum   		
              , i.Loop        		
              , i.ReqID       		
              , i.StartTime   		
              , i.EndTime     		
			  , h.OperatorName
			  , HWTChecksum =   BINARY_CHECKSUM
									(
										i.HeaderID
									  , i.VectorNum
									  , i.Loop
									  , i.ReqID
									  , i.StartTime
									  , i.EndTime
									)
		FROM	#inserted AS i
				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID 
				;

						
--  2)  DELETE vector records that are unchanged from temp storage
      DELETE	tmp
		FROM	#changes as tmp
	   WHERE	EXISTS
				(
				  SELECT	1
					FROM    hwt.Vector AS v
				   WHERE	v.HeaderID = tmp.HeaderID
							AND v.VectorNumber 	= tmp.VectorNum
							AND v.LoopNumber	= tmp.Loop
							AND v.HWTChecksum 	= tmp.HWTChecksum
				) 
				;

    --  exit if there is no remaining data
    IF NOT EXISTS( SELECT 1 FROM #changes )
        RETURN ;

		
--	3)	For legacy XML, remaining vectors need to be either matched with existing vectors, or assigned new vectorIDs.
	  UPDATE 	tmp 
		 SET	ID 	=	v.ID  
		FROM	#changes AS tmp 
				INNER JOIN labViewStage.vector AS v 
						ON v.HeaderID = tmp.HeaderID 
							AND v.VectorNum = tmp.VectorNum
							AND v.Loop = tmp.Loop 
							AND v.StartTime = tmp.StartTime 
				;
		
		
	 DECLARE 	@CurrentVectorID 	int ; 
	  SELECT 	@CurrentVectorID	=	ISNULL( MAX( VectorID ), 0 ) FROM hwt.Vector ; 
	  
	  
	  UPDATE 	tmp 
		 SET	@CurrentVectorID = ID = @CurrentVectorID + 1
		FROM	#changes AS tmp 
				LEFT JOIN labViewStage.vector AS v 
						ON v.HeaderID = tmp.HeaderID 
							AND v.VectorNum = tmp.VectorNum
							AND v.Loop = tmp.Loop 
							AND v.StartTime = tmp.StartTime 
	   WHERE 	v.ID IS NULL ;
							
							
							
--  4)  MERGE Vector changes from temp storage into hwt.Vector
	 

		WITH	changes AS
				(
				  SELECT	VectorID        =   tmp.ID
						  , HeaderID        =   tmp.HeaderID
						  , VectorNumber    =   tmp.VectorNum
						  , LoopNumber      =   tmp.Loop
						  , StartTime       =   CONVERT( datetime, tmp.StartTime )
						  , EndTime         =   NULLIF( CONVERT( datetime, tmp.EndTime ), '1900-01-01' )
						  , HWTChecksum     =   tmp.HWTChecksum
						  , UpdatedBy       =   tmp.OperatorName
					FROM	#changes AS tmp
				)
			  , vector AS
				(
				  SELECT	*
					FROM    hwt.Vector AS v
				   WHERE	EXISTS
							( 
							  SELECT	1 
								FROM 	#changes AS tmp
							   WHERE   	tmp.HeaderID = v.HeaderID
							)
				)
       
	   MERGE 	INTO vector AS tgt
				USING changes AS src
					ON src.VectorID = tgt.VectorID
    
	    WHEN 	MATCHED AND src.HWTChecksum <> tgt.HWTChecksum 
				THEN  UPDATE
						 SET	tgt.StartTime   =   src.StartTime
							  , tgt.EndTime     =   src.EndTime
							  , tgt.HWTChecksum =   src.HWTChecksum
							  , tgt.UpdatedBy   =   src.UpdatedBy
							  , tgt.UpdatedDate =   GETDATE()

	    WHEN 	NOT MATCHED BY TARGET 
				THEN  INSERT	(
									VectorID
								  , HeaderID
								  , VectorNumber
								  , LoopNumber
								  , StartTime
								  , EndTime
								  , HWTChecksum
								  , UpdatedDate
								  , UpdatedBy
								)
					  VALUES	(
									src.VectorID
								  , src.HeaderID
								  , src.VectorNumber
								  , src.LoopNumber
								  , src.StartTime
								  , src.EndTime
								  , src.HWTChecksum
								  , GETDATE()
								  , src.UpdatedBy
								) ;

--  4)  Insert tags for requirements into temp storage
    DROP TABLE IF EXISTS #tags ;

      SELECT	DISTINCT 
				HeaderID    =   tmp.HeaderID
			  , TagTypeID   =   tType.TagTypeID
			  , Name        =   tmp.ReqID
			  , Description =   'Requirement loaded from test dataset'
			  , UpdatedBy   =   tmp.OperatorName
			  , TagID       =   CONVERT( int, NULL )
		INTO	#tags
		FROM	#changes AS tmp
				CROSS JOIN hwt.TagType AS tType
	   WHERE 	tType.Name = 'ReqID'
					AND ISNULL( tmp.ReqID, '' ) != '' ;

      DELETE	FROM #tags
	   WHERE	Name IN ( N'NA', 'N/A' ) ;


--  5)  INSERT tags from temp storage into hwt.Tag
		WITH	newTags AS
				(
				  SELECT 	DISTINCT
							TagTypeID
						  , Name
						  , Description
						  , UpdatedBy
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
			  , UpdatedBy
			  , UpdatedDate =   GETDATE()
		FROM	newTags ;

    --  Apply new TagID back into temp storage
      UPDATE	tmp
		 SET	TagID   =   tag.TagID
		FROM	#tags AS tmp
				INNER JOIN hwt.Tag AS tag
						ON tag.TagTypeID = tmp.TagTypeID
							AND tag.Name = tmp.Name ;


--  6)  MERGE new header tag data into hwt.HeaderTag
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
														FOR XML PATH (''), TYPE
											).value('.', 'nvarchar(max)'), 1, 1, '' 
										) 
						; 
						
			 EXECUTE 	hwt.usp_AssignTagsToDatasets 
							@pUserID	= @OperatorName
						  , @pHeaderID	= @HeaderID 
						  , @pTagID		= @TagID 
						  , @pNotes		= 'Tag assigned during header load.'
						;

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