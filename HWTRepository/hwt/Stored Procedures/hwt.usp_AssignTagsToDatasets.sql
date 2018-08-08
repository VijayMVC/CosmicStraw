CREATE	PROCEDURE [hwt].[usp_AssignTagsToDatasets]
			(
				@pUserID	sysname			=	NULL
			  , @pHeaderID	nvarchar(max)
			  , @pTagID		nvarchar(max)
			  , @pNotes		nvarchar(200)	=	NULL
			)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_AssignTagsToDatasets
	Abstract:	Assigns existing tags to repository datasets

	Logic Summary
	-------------
	1)	INSERT data into hwt.Tag from input parameters

	Parameters
	----------
	@pUserID		sysname			UserID who is making the assignment
	@pHeaderID		nvarchar(max)	pipe-delimited list of datasets to which tags are assigned
	@pTagID			nvarchar(max)	pipe-delimited list of tags assigned to datasets
	@pNotes			nvarchar(200)	user comments documenting the tag assignment

	Notes
	-----
	If tag is already assigned to a dataset, update the assignment instead of inserting it

	Revision
	--------
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
										SELECT	[usp_AssignTagsToDatasets.@pUserID]		=	@pUserID
											  , [usp_AssignTagsToDatasets.@pHeaderID]	=	@pHeaderID
											  , [usp_AssignTagsToDatasets.@pTagID]		=	@pTagID
											  , [usp_AssignTagsToDatasets.@pNotes]		=	@pNotes

												FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
									)
			;

BEGIN TRY

	DROP TABLE IF EXISTS #HeaderTags ;
	DROP TABLE IF EXISTS #ExistingHeaderTags ;
	DROP TABLE IF EXISTS #headerTag ;
	DROP TABLE IF EXISTS #existingHeaderTag ;
	DROP TABLE IF EXISTS #newHeaderTag ;
	

--	1)	SELECT input parameters into temp storage
		--	use string splitter utility to parse out inbound parameters
	  SELECT	HeaderID	=	CONVERT( int, h.Item )
			  , TagID 		=	CONVERT( int, t.Item ) 	
			  , TagTypeName	=	v.TagTypeName
			  , TagName		=	v.TagName
		INTO	#HeaderTags
		FROM	hwt.vw_AllTags AS v
				INNER JOIN utility.ufn_SplitString( @pTagID, '|' ) AS t
						ON t.Item = v.TagID

				CROSS JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS h
				;


--	1)	SELECT hwt.HeaderTag data into temp storage
	  INSERT 	#HeaderTags
	  SELECT	HeaderID		=	CONVERT( int, h.Item )
			  , TagID 			=	ht.TagID 
			  , TagTypeName 	=	v.TagTypeName
			  , TagName			=	v.TagName
		FROM	hwt.HeaderTag  AS ht 
				INNER JOIN hwt.vw_AllTags v 
						ON v.TagID = ht.TagID 
				
				INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS h
						ON h.Item = ht.HeaderID 

	  EXCEPT	
	  SELECT 	HeaderID
			  , TagID 
			  , TagTypeName 
			  , TagName
		FROM 	#HeaderTags 
				; 


--	2)	Validation for more than one of given tag types 
	IF	EXISTS(	  SELECT	HeaderID
						  , TagTypeName
						  , COUNT(*)
					FROM	#HeaderTags
				   WHERE	TagTypeName IN( 'Project'
										  , 'Operator'
										  , 'TestMode'
										  , 'DataStatus'
										  , 'FunctionBlock'
										  , 'DeviceModel'
										  , 'Procedure' )
				GROUP BY	HeaderID, TagTypeName
				  HAVING	COUNT(*) > 1
			 )
	BEGIN
				
		 DECLARE	@HeaderID			int ;
		 DECLARE	@TagTypeName		nvarchar(20) ;
		 DECLARE	@ExistingTagName	nvarchar(100) ;
		 DECLARE	@NewTagNames		nvarchar(100) ;
		 DECLARE	@ErrorMessage		nvarchar(2048) ;

			WHILE EXISTS ( 
							  SELECT 	1
								FROM	#HeaderTags 
							   WHERE	TagTypeName IN( 	'Project'
														  , 'Operator'
														  , 'TestMode'
														  , 'DataStatus'
														  , 'FunctionBlock'
														  , 'DeviceModel'
														  , 'Procedure' )
							GROUP BY	HeaderID, TagTypeName
							  HAVING	COUNT(*) > 1			
				) 
			BEGIN 
	
				  SELECT	TOP 1
							@HeaderID		=	HeaderID
						  , @TagTypeName	=	TagTypeName
					FROM	#HeaderTags
				   WHERE	TagTypeName IN ( 	'Project'
											  , 'Operator'
											  , 'TestMode'
											  , 'DataStatus'
											  , 'FunctionBlock'
											  , 'DeviceModel'
											  , 'Procedure' )
				GROUP BY	HeaderID, TagTypeName
				  HAVING	COUNT(*) > 1
							;

				  SELECT	@ExistingTagName	=	t.Name
					FROM	hwt.Tag AS t
							INNER JOIN hwt.HeaderTag AS ht
									ON ht.TagID = t.TagID
									
							INNER JOIN hwt.TagType AS tType 
									ON tType.TagTypeID = t.TagTypeID 
								
				   WHERE	tType.Name = @TagTypeName
								AND ht.HeaderID = @HeaderID
							;

				  SELECT	@NewTagNames	=	STUFF
													( 	
														(  SELECT	', ' + t.TagName
															FROM	hwt.Tag AS t
																	INNER JOIN #HeaderTags AS ht
																			ON ht.TagID = t.TagID
															
																	INNER JOIN hwt.TagType AS tType
																			ON tType.TagTypeID = t.TagTypeID 
																			
														   WHERE	ht.TagTypeName = @TagTypeName
																		AND ht.HeaderID = @HeaderID
														ORDER BY	t.TagName
																	FOR XML PATH (''), TYPE
														).value('.', 'nvarchar(max)'), 1, 2, ''
													)
							;

				  SELECT	@ErrorMessage	=	CASE
													WHEN @ExistingTagName IS NULL
														THEN N'The %1 tags %2 cannot be assigned to dataset %3.  Only one %1 tag is allowed.'
													WHEN ( PATINDEX( '%,%', @NewTagNames ) > 0 )
														THEN N'Cannot assign %1 tags %2 to dataset %3.	%1 tag %4 is already assigned.'
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
							  , @p5			=	@pInputParameters
							;
				
				  DELETE	#HeaderTags WHERE HeaderID =  @HeaderID AND TagTypeName = @TagTypeName ; 
			END
		
		IF 	NOT EXISTS( SELECT 1 FROM #HeaderTag ) 
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Error Assigning Tags to Header -- check error logs.'
						  , @p1			=	@pInputParameters
						;
	END


--	3)	Load hwt.HeaderTag with tag assignments 
	  INSERT 	hwt.HeaderTag
				( HeaderID, TagID, Notes, UpdatedBy, UpdatedDate ) 
		
	  SELECT 	HeaderID
			  , TagID 
			  , Notes		=	ISNULL( @pNotes, '' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME() 
	    FROM 	#HeaderTags 
		
	  EXCEPT 
	  SELECT 	HeaderID 
			  , TagID 
			  , Notes		=	ISNULL( @pNotes, '' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME() 
		FROM 	hwt.HeaderTag
				; 

	  UPDATE 	hTag 
	     SET	Notes		=	ISNULL( @pNotes, '' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME() 
		FROM	hwt.HeaderTag AS hTag 
				INNER JOIN #HeaderTags AS tmp
					ON tmp.HeaderID = hTag.HeaderID 
						AND tmp.TagID = hTag.TagID 
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