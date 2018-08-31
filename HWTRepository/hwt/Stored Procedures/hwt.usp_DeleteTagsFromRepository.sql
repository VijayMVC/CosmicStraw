CREATE PROCEDURE
	hwt.usp_DeleteTagsFromRepository
		(
			@pUserID	sysname			=	NULL
		  , @pTagID		nvarchar(max)
		)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_DeleteTagsFromRepository
	Abstract:	Deletes tags from repository

	Logic Summary
	-------------
	1)	DELETE data from hwt.Tag based on input parameters

	Parameters
	----------
	@pUserID		sysname
	@pTagID			nvarchar(max)		pipe-delimited list of tags to delete from repository


	Notes
	-----
	DELETEs against hwt.Tag are actually executed in the trigger hwt.trg_Tag_delete
		Tags are physically deleted only if they are not assigned to any datasets

	Revision
	--------
	carsoc3		2018-02-01		alpha release
	carsoc3		2018-08-31		enhanced error processing

***********************************************************************************************************************************
*/
AS
SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

	  DELETE	t
		FROM	hwt.Tag AS t
	   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pTagID, '|' ) AS x
				   WHERE	x.Item = t.TagID
				) ;

	RETURN 0 ;

END TRY

BEGIN CATCH

 DECLARE	@pInputParameters	nvarchar(4000) ;

  SELECT	@pInputParameters	=	(
										SELECT	[usp_DeleteTagsFromRepository.@pUserID]		=	@pUserID
											  , [usp_DeleteTagsFromRepository.@pTagID]		=	@pTagID

												FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
									)
			;

	IF @@trancount > 0 ROLLBACK TRANSACTION ;

	EXECUTE		eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pInputParameters
				;

	RETURN 55555 ;

END CATCH
