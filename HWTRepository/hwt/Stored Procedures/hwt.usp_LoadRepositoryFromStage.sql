CREATE	PROCEDURE hwt.usp_LoadRepositoryFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadRepositoryFromStage
	Abstract:	Detect stage data changes and load them into HWTRepository

	Logic Summary
	-------------
	1)	EXECUTE procedures sequentially to extract data from labViewStage schema and apply to hwt schema
		--	scan labViewStage table for unpublished changes
		--	invoke proc if unpublished changes are found

	Parameters
	----------

	Notes
	-----

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling
								updates to support messaging architecture
									--	removed @pSourceTable
									--	invoked each proc sequentially



***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY


--	1)	EXECUTE procedures sequentially to extract data from labViewStage schema and apply to hwt schema

	IF	EXISTS( SELECT 1 FROM labViewStage.header WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadHeaderFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.equipment_element WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadEquipmentFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.option_element WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadOptionFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.appConst_element WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadAppConstFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.libraryInfo_file WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadLibraryFileFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.vector WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadVectorFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.vector_element WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadVectorElementFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.result_element WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadVectorResultFromStage ;


	IF	EXISTS( SELECT 1 FROM labViewStage.error_element WHERE PublishDate IS NULL )
		EXECUTE hwt.usp_LoadTestErrorFromStage ;


	RETURN 0 ;

END TRY
BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ;

	RETURN 55555 ;

END CATCH