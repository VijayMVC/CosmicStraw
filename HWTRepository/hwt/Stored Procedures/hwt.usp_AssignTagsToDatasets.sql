CREATE PROCEDURE hwt.usp_AssignTagsToDatasets
	( 
	    @pUserID	sysname			=	NULL
	  , @pHeaderID	nvarchar(max) 
	  , @pTagID		nvarchar(max) 
	  , @pNotes		nvarchar(200)	=	NULL
	)
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_AssignTagsToDatasets
    Abstract:   Assigns existing tags to repository datasets

    Logic Summary
    -------------
    1)  INSERT data into hwt.Tag from input parameters 

    Parameters
    ----------
    @pUserID        sysname			UserID who is making the assignment
    @pHeaderID     	nvarchar(max) 	pipe-delimited list of datasets to which tags are assigned
    @pTagID         nvarchar(max) 	pipe-delimited list of tags assigned to datasets 
    @pNotes			nvarchar(200)	user comments documenting the tag assignment
	
    Notes
    -----
	If tag is already assigned to a dataset, update the assignment instead of inserting it

    Revision
    --------
    carsoc3     2018-04-27		production release
	carsoc3		2018-08-31		added @pDataID for enhanced error messaging

***********************************************************************************************************************************
*/	
AS

SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

	DROP TABLE IF EXISTS #header ;
	DROP TABLE IF EXISTS #tag ;
	DROP TABLE IF EXISTS #headerTag ;
	
	 DECLARE	@pDataID	int	=	TRY_CONVERT( int, @pHeaderID ) ; 

--	1)	load dataset IDs into temp storage	
	  SELECT	HeaderID = CONVERT( int, x.Item )
	    INTO	#header 
	    FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x 
				; 

	
--	2)	load tag IDs into temp storage	
	  SELECT	TagID = CONVERT( int, x.Item )
		INTO	#tag 
	    FROM	utility.ufn_SplitString( @pTagID, '|' ) AS x 
				; 
		
--	2)	load current assignments into temp storage	
	  CREATE	TABLE #headerTag 
					( 
						HeaderID	int 
					  , TagID		int 
					  , TagTypeName	nvarchar( 50 )  
					) 
				; 
				
--	3)	Validation for too many of certain tag types 	
	  INSERT 	#headerTag	
	  SELECT	ht.HeaderID, ht.TagID, v.TagTypeName  
	    FROM	hwt.HeaderTag AS ht
				INNER JOIN #header AS h 
						ON h.HeaderID = ht.HeaderID 
				
				INNER JOIN hwt.vw_AllTags AS v 
						ON v.TagID = ht.TagID 
				; 
				
	    WITH 	newTags AS 
				(
				  SELECT 	TagID
						  , TagTypeName
					FROM 	hwt.vw_AllTags AS v 
				   WHERE 	EXISTS( SELECT 1 FROM #tag AS t WHERE t.TagID = v.TagID ) 
				) 
	  INSERT 	#headerTag 
					( HeaderID, TagID, TagTypeName ) 
	  SELECT	HeaderID	=	h.HeaderID 
			  , TagID 		=	t.TagID 
			  , TagTypeName	=	t.TagTypeName 
		FROM	#header AS h 
				CROSS JOIN newTags AS t 
	   WHERE	NOT EXISTS 
					(
					  SELECT 1 FROM #headerTag AS ht WHERE ht.HeaderID = h.HeaderID AND ht.TagID = t.TagID 
					) 
				; 
				
	IF 	EXISTS
			( 
				  SELECT 	HeaderID
						  , TagTypeName
						  , COUNT(*) 
					FROM 	#headerTag 
				   WHERE	TagTypeName IN ( 'Project', 'Operator', 'TestMode', 'DataStatus', 'FunctionBlock', 'DeviceModel', 'Procedure' ) 
				GROUP BY	HeaderID, TagTypeName
				  HAVING 	COUNT(*) > 1 
			) 
		BEGIN 
			 DECLARE	@HeaderID 			int ; 
			 DECLARE 	@TagTypeName		nvarchar(20) ; 
			 DECLARE 	@ExistingTagName 	nvarchar(100) ; 
			 DECLARE 	@NewTagNames 		nvarchar(100) ; 
			 DECLARE 	@ErrorMessage		nvarchar(2048) ; 
			  
			  SELECT	TOP 1 
						@HeaderID		=	HeaderID
					  , @TagTypeName	=	TagTypeName 
				FROM 	#headerTag 
			   WHERE	TagTypeName IN ( 'Project', 'Operator', 'TestMode', 'DataStatus', 'FunctionBlock', 'DeviceModel', 'Procedure' ) 
			GROUP BY	HeaderID, TagTypeName
			  HAVING 	COUNT(*) > 1 
						;
			
		      SELECT 	@ExistingTagName 	=	v.TagName 
			    FROM 	hwt.vw_AllTags AS v
						INNER JOIN hwt.HeaderTag AS ht
								ON ht.TagID = v.TagID 
				WHERE 	v.TagTypeName = @TagTypeName
							AND ht.HeaderID = @HeaderID 
						; 
						
			  SELECT 	@NewTagNames 	=	STUFF
										(
											(	
											  SELECT	', ' + t.TagName
												FROM 	hwt.vw_AllTags AS t 
														INNER JOIN #headerTag AS ht 
																ON ht.TagID = t.TagID
											   WHERE 	ht.TagTypeName = @TagTypeName
														AND ht.HeaderID = @HeaderID 
														AND t.TagName != ISNULL( @ExistingTagName, '' ) 
											ORDER BY  	t.TagName 
														FOR XML PATH (''), TYPE
											).value('.', 'nvarchar(max)'), 1, 2, '' 
										) 
						; 

			  SELECT 	@ErrorMessage	=	CASE 
												WHEN @ExistingTagName IS NULL 
													THEN N'Datasets can have only one %1 tag. The tags %2 cannot be assigned to the same dataset.' 
												WHEN ( PATINDEX( '%,%', @NewTagNames ) > 0 )
													THEN N'Cannot assign %1 tags %2 to dataset %3.  %1 tag %4 is already assigned.'
												ELSE 
													N'Cannot assign %1 tag %2 to dataset %3.  %1 tag %4 is already assigned.'
											END
						
			 EXECUTE	eLog.log_ProcessEventLog 	
							@pProcID	=	@@PROCID
						  , @pMessage	=	@ErrorMessage
						  , @p1			=	@TagTypeName 
						  , @p2			=	@NewTagNames
						  , @p3			=	@HeaderID 
						  , @p4			=	@ExistingTagName
						  , @pDataID	=	@HeaderID 
						;
		END
		
		

--	3)	MERGE assignment data into hwt.HeaderTag 
	    ;
		WITH 	assignments AS 
				( 
				  SELECT	HeaderID	=	h.HeaderID 
			              , TagID 		=	t.TagID 
						  , Notes 		=	ISNULL( @pNotes, '' )
						  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
						  , UpdatedDate	=	GETDATE()
					FROM	#header AS h 
							CROSS JOIN #tag AS t 
				) 
				
	   MERGE	INTO hwt.HeaderTag AS hTag 
				USING assignments AS src 
					ON hTag.HeaderID = src.HeaderID 
						AND hTag.TagID = src.TagID 		
		WHEN 	MATCHED 
				THEN  UPDATE 
						 SET	Notes 		=	src.Notes   		
							  , UpdatedBy	=	src.UpdatedBy   	
							  , UpdatedDate	=	src.UpdatedDate   	
		WHEN	NOT MATCHED BY TARGET 
				THEN  INSERT( HeaderID, TagID, Notes, UpdatedBy, UpdatedDate )
					  VALUES( src.HeaderID, src.TagID, src.Notes, src.UpdatedBy, src.UpdatedDate ) ; 
	
	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE		eLog.log_CatchProcessing @pProcID = @@PROCID, @pDataID = @pDataID ; 
	 
	RETURN 55555 ; 

END CATCH
