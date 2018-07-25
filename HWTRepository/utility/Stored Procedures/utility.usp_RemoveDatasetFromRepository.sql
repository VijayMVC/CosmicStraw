CREATE	PROCEDURE utility.usp_RemoveDatasetFromRepository
			(
				@pHeaderID		nvarchar(max)
			  , @pIncludeStage	int				= 0
			)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_RemoveDatasetFromRepository
	Abstract:	Remove designated datasets from HWT Repository

	Logic Summary
	-------------
	1)	validate input parameters
	2)	DELETE data from all tables related to given header(s)
	3)	DELETE data from labViewStage from all tables related to given header(s), only if directed by parameters

	Parameters
	----------
	@pHeaderID		nvarchar(max)	pipe-delimited list of datasets for which data needs to be deleted
	@pIncludeStage	int				boolean that instructs procedure whether or not to delete labViewStage data

	Notes
	-----
	This proc removes only data directly related to a given header, and vectors for that header.
		Data related to neither a header nor a vector are removed from the data

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
										SELECT	[usp_RemoveDatasetFromRepository.@pHeaderID]		=	@pHeaderID
											  , [usp_RemoveDatasetFromRepository.@pIncludeStage]	=	@pIncludeStage

												FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
									)
			;

BEGIN TRY

 DECLARE	@ErrorMessage	nvarchar(max)	=	NULL ;

--	Validate @pHeaderID, must not be NULL

IF	@pHeaderID IS NULL
BEGIN

	  SELECT	@ErrorMessage = N'Input parameter @pHeaderID must not be NULL ' ;

	 EXECUTE	eLog.log_ProcessEventLog
					@pProcID		=	@@PROCID
				  , @pMessage		=	@ErrorMessage
				  , @pSeverity		=	16
				  , @pRaiserror		=	1
				  , @p1				=	@pInputParameters
				;
END


--	DELETE Test Errors
  DELETE	tmp
	FROM	hwt.TestError AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	hwt.Vector AS v
							INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
									ON x.Item = v.HeaderID
				   WHERE	v.VectorID = tmp.VectorID
				)
			;


--	DELETE Vector Results
  DELETE	tmp
	FROM	hwt.VectorResult AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	hwt.Vector AS v
							INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
									ON x.Item = v.HeaderID
				   WHERE	v.VectorID = tmp.VectorID
				)
			;


--	DELETE Vector Elements
  DELETE	tmp
	FROM	hwt.VectorElement AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	hwt.Vector AS v
							INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
									ON x.Item = v.HeaderID
				   WHERE	v.VectorID = tmp.VectorID
				)
			;


--	DELETE Vector Requirements
  DELETE	tmp
	FROM	hwt.VectorRequirement AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	hwt.Vector AS v
							INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
									ON x.Item = v.HeaderID
				   WHERE	v.VectorID = tmp.VectorID
				)
			;


--	DELETE Vector
  DELETE	tmp
	FROM	hwt.Vector AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


--	DELETE HeaderTag
  DELETE	tmp
	FROM	hwt.HeaderTag AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


--	DELETE HeaderOption
  DELETE	tmp
	FROM	hwt.HeaderOption AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


--	DELETE HeaderLibraryFile
  DELETE	tmp
	FROM	hwt.HeaderLibraryFile AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


--	DELETE HeaderEquipment
  DELETE	tmp
	FROM	hwt.HeaderEquipment AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


--	DELETE HeaderAppConst
  DELETE	tmp
	FROM	hwt.HeaderAppConst AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


--	DELETE Header
  DELETE	tmp
	FROM	hwt.Header AS tmp
   WHERE	EXISTS
				(
				  SELECT	1
					FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
				   WHERE	x.Item = tmp.HeaderID
				)
			;


	IF( @pIncludeStage = 1 )
	BEGIN
		  DELETE	tmp
			FROM	labViewStage.error_element AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	labViewStage.vector AS v
									INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
											ON x.Item = v.HeaderID
						   WHERE	v.ID = tmp.VectorID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.result_element AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	labViewStage.vector AS v
									INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
											ON x.Item = v.HeaderID
						   WHERE	v.ID = tmp.VectorID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.vector_element AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	labViewStage.vector AS v
									INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x
											ON x.Item = v.HeaderID
						   WHERE	v.ID = tmp.VectorID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.vector AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
						   WHERE	x.Item = tmp.HeaderID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.appConst_element AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
						   WHERE	x.Item = tmp.HeaderID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.equipment_element AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
						   WHERE	x.Item = tmp.HeaderID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.libraryInfo_file AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
						   WHERE	x.Item = tmp.HeaderID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.option_element AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
						   WHERE	x.Item = tmp.HeaderID
						)
					;


		  DELETE	tmp
			FROM	labViewStage.header AS tmp
		   WHERE	EXISTS
						(
						  SELECT	1
							FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS x
						   WHERE	x.Item = tmp.ID
						)
					;



	END

  SELECT	@ErrorMessage = N'Datasets DELETEd from Repository' ;
 EXECUTE	eLog.log_ProcessEventLog
				@pProcID	=	@@PROCID
			  , @pMessage	=	@ErrorMessage
			  , @pSeverity	=	0
			  , @p1			=	@pInputParameters
			;

  RETURN	0 ;

END TRY
BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @p1			=	@pInputParameters
				;

	RETURN 55555 ;

END CATCH
