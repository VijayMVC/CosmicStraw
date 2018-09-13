CREATE	PROCEDURE
	[hwt].[usp_AssignTagsToDatasets]
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

 DECLARE	@pInputParameters	nvarchar(4000) ;

 DECLARE	@headerTag	TABLE	(
									HeaderID			int
									, TagID				int
									, TagTypeName		nvarchar(50)
									, TagName			nvarchar(50)
									, IsTagAssigned		int
								)
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


--	1)	SELECT input parameters into temp storage
		--	use string splitter utility to parse out inbound parameters
	  INSERT	@headerTag
					( HeaderID, TagID, TagTypeName, TagName, IsTagAssigned )
	  SELECT	HeaderID		=	CONVERT( int, h.Item )
			  , TagID			=	CONVERT( int, t.Item )
			  , TagTypeName		=	v.TagTypeName
			  , TagName			=	v.TagName
			  , IsTagAssigned	=	0
		FROM	hwt.vw_AllTags AS v
				INNER JOIN utility.ufn_SplitString( @pTagID, '|' ) AS t
						ON t.Item = v.TagID

				CROSS JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS h
				;

--	1)	UPDATE tags that have already been assigned
	  UPDATE	tmp
		 SET	IsTagAssigned	=	1
		FROM	@headerTag AS tmp
	   WHERE	EXISTS	(
						  SELECT	1
							FROM	hwt.HeaderTag AS ht
						   WHERE	ht.HeaderID = tmp.HeaderID
										AND ht.TagID = tmp.TagID
						)
				;


--	2)	Validation for more than one of given tag types

	 DECLARE	@headerID			int ;
	 DECLARE	@tagTypeName		nvarchar(20) ;
	 DECLARE	@existingTagName	nvarchar(100) ;
	 DECLARE	@newTagNames		nvarchar(100) ;
	 DECLARE	@errorMessage		nvarchar(2048) ;

	 DECLARE	headerTagCursor
	  CURSOR	LOCAL FORWARD_ONLY STATIC READ_ONLY
		 FOR	  SELECT	HeaderID
						  , TagTypeName
					FROM	(
							  SELECT	HeaderID, TagTypeName
								FROM	@headerTag
							   WHERE	TagTypeName IN( N'Project', N'Operator', N'TestMode', N'DataStatus'
															, N'FunctionBlock', N'DeviceModel', N'Procedure' )
											AND IsTagAssigned = 0 
							   UNION ALL
							  SELECT	ht.HeaderID, ht.TagTypeName
								FROM	hwt.vw_HeaderTag_expanded AS ht
										INNER JOIN	@headerTag AS tmp
												ON	tmp.HeaderID = ht.HeaderID
													AND tmp.TagTypeName = ht.TagTypeName
							) as x
				GROUP BY	HeaderID, TagTypeName
				  HAVING	COUNT(*) > 1
				;

		OPEN	headerTagCursor ;

	   FETCH	NEXT FROM headerTagCursor
		INTO	@headerID, @tagTypeName
				;

	   WHILE	@@FETCH_STATUS = 0
				BEGIN

					  SELECT	@existingTagName	=	TagName
						FROM	hwt.vw_HeaderTag_expanded
					   WHERE	TagTypeName = @TagTypeName
									AND HeaderID = @HeaderID
								;

					  SELECT	@newTagNames	=	STUFF
														(
															(
															  SELECT	', ' + TagName
																FROM	@headerTag
															   WHERE	TagTypeName = @tagTypeName
																			AND HeaderID = @headerID
																			AND	IsTagAssigned = 0

															ORDER BY	TagName
																		FOR XML PATH (''), TYPE
															).value('.', 'nvarchar(max)'), 1, 2, ''
														)
								;

					  SELECT	@errorMessage	=	CASE
														WHEN @existingTagName IS NULL
															THEN N'The %1 tags %2 cannot be assigned to dataset %3.	 Only one %1 tag is allowed.'
														WHEN ( PATINDEX( '%,%', @newTagNames ) > 0 )
															THEN N'Cannot assign %1 tags %2 to dataset %3.	%1 tag %4 is already assigned.'
														ELSE
															N'Cannot assign %1 tag %2 to dataset %3.  %1 tag %4 is already assigned.'
													END
								;

					 EXECUTE	eLog.log_ProcessEventLog
									@pProcID	=	@@PROCID
								  , @pRaiserror	=	0
								  , @pMessage	=	@errorMessage
								  , @p1			=	@tagTypeName
								  , @p2			=	@newTagNames
								  , @p3			=	@headerID
								  , @p4			=	@existingTagName
								;

					   FETCH	NEXT FROM headerTagCursor
						INTO	@headerID, @tagTypeName
								;

				END

		IF	@errorMessage IS NOT NULL
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	N'Error Assigning Tags to Header -- check error log for details.  Input Parameters: %1 '
						  , @p1			=	@pInputParameters
						;


--	3)	Load hwt.HeaderTag with tag assignments
	  INSERT	hwt.HeaderTag
				( HeaderID, TagID, Notes, UpdatedBy, UpdatedDate )

	  SELECT	HeaderID
			  , TagID
			  , Notes		=	ISNULL( @pNotes, N'' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME()
		FROM	@headerTag
	   WHERE	IsTagAssigned = 0
				;


	  UPDATE	hTag
		 SET	Notes		=	ISNULL( @pNotes, N'' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME()
		FROM	hwt.HeaderTag AS hTag
				INNER JOIN @headerTag AS tmp
					ON tmp.HeaderID = hTag.HeaderID
						AND tmp.TagID = hTag.TagID
	   WHERE	IsTagAssigned = 1
				;

	RETURN 0 ;

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pInputParameters
				;

	RETURN 55555 ;

END CATCH