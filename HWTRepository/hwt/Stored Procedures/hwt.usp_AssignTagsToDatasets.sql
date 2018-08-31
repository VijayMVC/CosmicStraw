CREATE PROCEDURE
	hwt.usp_AssignTagsToDatasets
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
	1)	INSERT data into hwt.HeaderTag from input parameters

	Parameters
	----------
	@pUserID		sysname			UserID who is making the assignment
	@pHeaderID		nvarchar(max)	pipe-delimited list of datasets to which tags are assigned
	@pTagID			nvarchar(max)	pipe-delimited list of tags assigned to datasets
	@pNotes			nvarchar(200)	user comments documenting the tag assignment

	Notes
	-----
	If tag is already assigned to a dataset, the new assignment is ignored

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling
								labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

SET NOCOUNT, XACT_ABORT ON ;

--	enhanced error handling variables
 DECLARE	@pLogID				int
		  , @p1					sql_variant
		  , @p2					sql_variant
		  , @p3					sql_variant
		  , @p4					sql_variant
		  , @p5					sql_variant
		  , @p6					sql_variant

		  , @pInputParameters	nvarchar(4000)
		  , @pErrorData			xml
		  , @pMessage			nvarchar(2048)
			;

 DECLARE	@errorLogEntries	TABLE	(
											LogID			INT
										  , ErrorMessage	NVARCHAR(2048)
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
	DROP TABLE IF EXISTS #headerTag ;
	  SELECT	HeaderID	=	CONVERT( int, h.Item )
			  , TagID		=	CONVERT( int, t.Item )
			  , TagName		=	v.TagName
			  , TagTypeName	=	v.TagTypeName
		INTO	#headerTag
		FROM	hwt.vw_AllTags AS v
				INNER JOIN	utility.ufn_SplitString( @pTagID, '|' ) AS t
						ON	t.Item = v.TagID

				CROSS JOIN	utility.ufn_SplitString( @pHeaderID, '|' ) AS h
				;


--	1)	SELECT hwt.HeaderTag data into temp storage
	  INSERT	#headerTag
	  SELECT	HeaderID		=	CONVERT( int, h.Item )
			  , TagID			=	ht.TagID
			  , TagName			=	ht.TagName
			  , TagTypeName		=	ht.TagTypeName
		FROM	hwt.vw_HeaderTag_expanded AS ht
				INNER JOIN	utility.ufn_SplitString( @pHeaderID, '|' ) AS h
						ON	h.Item = ht.HeaderID

	  EXCEPT
	  SELECT	HeaderID
			  , TagID
			  , TagName
			  , TagTypeName
		FROM	#headerTag
				;


--	2)	Validate for more than one of certain tag types, this is an error condition
	IF	EXISTS(	  SELECT	HeaderID
						  , TagTypeName
						  , COUNT(*)
					FROM	#headerTag
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
	--	These tag types may not have more than one tag assigned to a dataset.
	BEGIN

		 DECLARE	@headerID			int
				  , @tagTypeName		nvarchar(20)
				  , @existingTagName	nvarchar(100)
				  , @newTagNames		nvarchar(100)
				  , @errorMessage		nvarchar(2048)
					;

		WHILE	EXISTS (
						  SELECT	1
							FROM	#headerTag
						   WHERE	TagTypeName IN(		'Project'
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

			  SELECT	@headerID			=	NULL
					  , @tagTypeName		=	NULL
					  , @existingTagName	=	NULL
					  , @newTagNames		=	NULL
					  , @errorMessage		=	NULL
						;

			--	get the header and tag type where the error condition exists
			  SELECT	TOP 1
						@headerID		=	HeaderID
					  , @tagTypeName	=	TagTypeName
				FROM	#headerTag
			   WHERE	TagTypeName IN (	'Project'
										  , 'Operator'
										  , 'TestMode'
										  , 'DataStatus'
										  , 'FunctionBlock'
										  , 'DeviceModel'
										  , 'Procedure' )
			GROUP BY	HeaderID, TagTypeName
			  HAVING	COUNT(*) > 1
						;

			--	find any tags currently assigned
			  SELECT	@existingTagName	=	ht.TagName
				FROM	hwt.vw_HeaderTag_expanded AS ht
			   WHERE	ht.TagTypeName = @tagTypeName
							AND ht.HeaderID = @HeaderID
						;

			--	list the tags that are supposed to be assigned ( leaving out tags already assigned )
			  SELECT	@newTagNames	=	STUFF
												(
													(  SELECT	', ' + v.TagName
														FROM	hwt.vw_AllTags AS v
																INNER JOIN #headerTag AS ht
																		ON ht.TagID = v.TagID

													   WHERE	v.TagTypeName = @TagTypeName
																	AND ht.HeaderID = @HeaderID
																	AND v.TagName <> ISNULL( @ExistingTagName, '' )
													ORDER BY	v.TagName
																FOR XML PATH (''), TYPE
													).value('.', 'nvarchar(max)'), 1, 2, ''
												)
						;

			--	review the data and determine correct error message
			  SELECT	@ErrorMessage	=	CASE
												WHEN @ExistingTagName IS NULL					--	two or more tags assigned where none exist
													THEN N'The %1 tags %2 cannot be assigned to dataset %3.	 Only one %1 tag is allowed.'
												WHEN ( PATINDEX( '%,%', @NewTagNames ) > 0 )	--	one tag exists, trying to assign more than one new tag
													THEN N'Cannot assign %1 tags %2 to dataset %3.	%1 tag %4 is already assigned.'
												ELSE											--	one tag exists, trying to assign additonal tag
													N'Cannot assign %1 tag %2 to dataset %3.  %1 tag %4 is already assigned.'
											END

			--	write error to log, do not raise error yet, we want to capture all errors before exiting
			 EXECUTE	eLog.log_ProcessEventLog
							@pProcID		=	@@PROCID
						  , @pMessage		=	@ErrorMessage
						  , @pRaiserror		=	0
						  , @p1				=	@TagTypeName
						  , @p2				=	@NewTagNames
						  , @p3				=	@HeaderID
						  , @p4				=	@ExistingTagName
						  , @pErrorData		=	@pInputParameters
						  , @pLogID			=	@pLogID		OUTPUT
						;

			  INSERT	@errorLogEntries
			  SELECT	@pLogID, @ErrorMessage
						;

			  DELETE	#headerTag
			   WHERE	HeaderID = @HeaderID
							AND TagTypeName = @TagTypeName ;
			END


	END

	IF	EXISTS(	SELECT 1 FROM @errorLogEntries )
	BEGIN
		  SELECT	@pErrorData	=	(
									  SELECT	(
												  SELECT	LogID
													FROM	@errorLogEntries
															FOR XML PATH( 'eLog.EventLogEntry' ), TYPE
												)
											  , (
												  SELECT	@pInputParameters
															FOR XML PATH( 'InputParameters' ), TYPE
												)
												FOR XML PATH( 'usp_AssignTagsToDatasets' ), TYPE
									)
				  , @pMessage	=	STUFF	(
												(
												  SELECT	NCHAR(13) + NCHAR(10) + ErrorMessage
													FROM	@errorLogEntries
												ORDER BY	LogID
															FOR XML PATH (''), TYPE
												).value('.', 'nvarchar(max)'), 1, 2, ''
											)
					;

		 EXECUTE	eLog.log_ProcessEventLog
							@pProcID	=	@@PROCID
						  , @pMessage	=	@pMessage
						  , @pErrorData	=	@pErrorData
					;
	END

--	3)	Load hwt.HeaderTag with tag assignments

	  INSERT	hwt.HeaderTag
				( HeaderID, TagID, Notes, UpdatedBy, UpdatedDate )

	  SELECT	HeaderID
			  , TagID
			  , Notes		=	ISNULL( @pNotes, '' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME()
		FROM	#headerTag

	  EXCEPT
	  SELECT	HeaderID
			  , TagID
			  , Notes		=	ISNULL( @pNotes, '' )
			  , UpdatedBy	=	ISNULL( @pUserID, CURRENT_USER )
			  , UpdatedDate =	SYSDATETIME()
		FROM	hwt.HeaderTag
				;

	RETURN 0 ;

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID		=	@@PROCID
				  , @pErrorData		=	@pInputParameters
				;

	RETURN 55555 ;

END CATCH