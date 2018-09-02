CREATE PROCEDURE
	hwt.usp_LoadRepositoryFromStage
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadRepositoryFromStage
	Abstract:	Detect stage data changes and load them into HWTRepository

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	EXECUTE procedures to load hwt Header data if required
	3)	EXECUTE procedures to load hwt Vector data if required
	4)	EXECUTE sp_releaseapplock to release lock

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

	 DECLARE	@loadHeader		TABLE	( HeaderID	int ) ;
	 DECLARE	@loadHeaderXML	xml ;

	 DECLARE	@loadVector		TABLE	( VectorID	int ) ;
	 DECLARE	@loadVectorXML	xml ;

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


--	2)	EXECUTE procedures to load hwt Header data if required
	IF	EXISTS(	SELECT 1 FROM labViewStage.LoadHWTHeader )
	BEGIN

		  DELETE	labViewStage.LoadHWTHeader
		  OUTPUT	deleted.HeaderID
			INTO	@loadHeader( HeaderID )
					;

		  SELECT	@loadHeaderXML	=	(
										  SELECT	(
													  SELECT	[@value] = HeaderID
														FROM	@loadHeader
																FOR XML PATH( 'HeaderID' ), TYPE
													)
													FOR XML PATH( 'LoadHeader' ), TYPE
										)
					;

		 EXECUTE hwt.usp_LoadEquipmentFromStage		@pHeaderXML	=	@loadHeaderXML ;
		 EXECUTE hwt.usp_LoadAppConstFromStage		@pHeaderXML	=	@loadHeaderXML ;
		 EXECUTE hwt.usp_LoadOptionFromStage		@pHeaderXML	=	@loadHeaderXML ;
		 EXECUTE hwt.usp_LoadLibraryFileFromStage	@pHeaderXML	=	@loadHeaderXML ;
	END


--	3)	EXECUTE procedures to load hwt Vector data if required
	IF	EXISTS(	SELECT 1 FROM labViewStage.LoadHWTVector )
	BEGIN

		  DELETE	labViewStage.LoadHWTVector
		  OUTPUT	deleted.VectorID
			INTO	@loadVector( VectorID )
					;

		  SELECT	@loadVectorXML	=	(
										  SELECT	(
													  SELECT	[@value] = VectorID
														FROM	@loadVector
																FOR XML PATH( 'VectorID' ), TYPE
													)
													FOR XML PATH( 'LoadVector' ), TYPE
										)
					;

		 EXECUTE	hwt.usp_LoadVectorElementFromStage		@pVectorXML	=	@loadVectorXML ;
		 EXECUTE	hwt.usp_LoadVectorResultFromStage		@pVectorXML	=	@loadVectorXML ;
		 EXECUTE	hwt.usp_LoadVectorErrorFromStage		@pVectorXML	=	@loadVectorXML ;

	END


--	4)	EXECUTE sp_releaseapplock to release lock
	EXECUTE	sp_releaseapplock	@Resource	=	@procedureName ;


	RETURN 0 ;

END TRY

BEGIN CATCH

	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	( SELECT @loadHeaderXML )
										  , ( SELECT @loadVectorXML )
											FOR XML PATH( 'usp_LoadRepositoryFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pErrorData
				;

	RETURN 55555 ;

END CATCH
