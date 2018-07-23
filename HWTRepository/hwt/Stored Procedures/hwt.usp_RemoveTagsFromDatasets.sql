﻿CREATE	PROCEDURE hwt.usp_RemoveTagsFromDatasets
			(
				@pUserID	sysname			=	NULL
			  , @pHeaderID	nvarchar(max)
			  , @pTagID		nvarchar(max)
			)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_RemoveTagsFromDatasets
	Abstract:	Un-assign tags from headers

	Logic Summary
	-------------
	1)	SELECT input parameters into temp storage
	2)	DELETE tags assignments from hwt.HeaderTag

	Parameters
	----------
	@pHeaderID	nvarchar(max)	Pipe-delimited list of headers affected by the tag unassignement
	@pTagID		nvarchar(max)	Pipe-delimited list of tags to be unassigned from headers


	Notes
	-----


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
										SELECT	[usp_RemoveTagsFromDatasets.@pUserID]	=	@pUserID
											  , [usp_RemoveTagsFromDatasets.@pHeaderID] =	@pHeaderID
											  , [usp_RemoveTagsFromDatasets.@pTagID]	=	@pTagID

												FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
									)
			;

BEGIN TRY

	DROP TABLE IF EXISTS #hTags ;

--	1)	SELECT input parameters into temp storage
	  SELECT	HeaderID	=	CONVERT( int, h.Item )
			  , TagID		=	CONVERT( int, t.Item )
		INTO	#hTags
		FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS h
				CROSS JOIN
					utility.ufn_SplitString( @pTagID, '|' ) AS t ;


--	2)	DELETE tags assignments from hwt.HeaderTag
	  DELETE	hTag
		FROM	hwt.HeaderTag AS hTag

				INNER JOIN
					#hTags AS tmp
						ON tmp.HeaderID = hTag.HeaderID
							AND tmp.TagID = hTag.TagID ;

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
