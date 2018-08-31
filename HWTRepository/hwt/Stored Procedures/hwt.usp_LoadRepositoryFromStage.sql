CREATE PROCEDURE
	hwt.usp_LoadRepositoryFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadRepositoryFromStage
	Abstract:	Detect stage data changes and load them into HWTRepository

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	EXECUTE each procedure to extract data from labViewStage schema and publish to hwt schema
	3)	EXECUTE sp_releaseapplock to release lock

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



--	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
		--	if lock cannot be acquired, procedure is already running from another transaction in the database
		--	when lock is acquired, it is released automatically on COMMIT or ROLLBAC
	 DECLARE	@applock		int
			  , @procedureName	sysname	=	OBJECT_NAME( @@PROCID )
				;

	 EXECUTE	@applock	=	sp_getapplock	@Resource		=	@procedureName
											  , @LockMode		=	N'Exclusive'
											  , @LockTimeout	=	0
											  , @LockOwner		=	N'Transaction'
				;

	IF	( @applock < 0 )
		RETURN 0 ;


--	2)	EXECUTE procedures sequentially to extract data from labViewStage schema and apply to hwt schema
	--	should execute every five seconds while data exists.
	--	if no data exists, break and end processing

	--EXECUTE hwt.usp_LoadHeaderFromStage ;		--	This proc is executed in trigger on labViewStage.header

	--EXECUTE hwt.usp_LoadVectorFromStage ;		--	This proc is executed in trigger on labViewStage.vector

	EXECUTE hwt.usp_LoadEquipmentFromStage ;

	EXECUTE hwt.usp_LoadAppConstFromStage ;

	EXECUTE hwt.usp_LoadOptionFromStage ;

	EXECUTE hwt.usp_LoadLibraryFileFromStage ;

	EXECUTE hwt.usp_LoadVectorElementFromStage ;

	EXECUTE hwt.usp_LoadVectorResultFromStage ;

	EXECUTE hwt.usp_LoadVectorErrorFromStage ;


--	3)	EXECUTE sp_releaseapplock to release lock
	EXECUTE	sp_releaseapplock	@Resource	=	@procedureName ;


	RETURN 0 ;

END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ;

	RETURN 55555 ;

END CATCH
