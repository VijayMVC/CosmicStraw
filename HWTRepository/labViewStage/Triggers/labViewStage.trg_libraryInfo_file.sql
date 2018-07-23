CREATE TRIGGER	labViewStage.trg_libraryInfo_file
			ON	labViewStage.libraryInfo_file
	INSTEAD OF	INSERT
/*
***********************************************************************************************************************************

	Procedure:	hwt.trg_libraryInfo_file
	Abstract:	Loads libraryInfo_file records into staging environment

	Logic Summary
	-------------
	1)	Load trigger data into temp storage
	2)	Load repository libraryInfo data from stage data
	3)	INSERT updated trigger data from temp storage into labViewStage


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@CurrentID int ;

	  SELECT	@CurrentID = ISNULL( MAX( ID ), 0 ) FROM labViewStage.libraryInfo_file ;

--	1)	Load trigger data into temp storage
	  SELECT	i.ID
			  , i.HeaderID
			  , FileName	=	REPLACE( REPLACE( REPLACE( i.FileName, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , FileRev		=	REPLACE( REPLACE( REPLACE( i.FileRev, '&amp;', '&' ), '&lt;', '<' ), '&gt;', '>' )
			  , i.Status
			  , i.HashCode
			  , i.CreatedDate
		INTO	#inserted
		FROM	inserted AS i
				;


	  UPDATE	#inserted
		 SET	@CurrentID = ID = @CurrentID + 1
	   WHERE	ISNULL( ID, 0 ) = 0
				;

--	2)	Load repository libraryInfo_file data from stage data
	 EXECUTE	hwt.usp_LoadRepositoryFromStage
					@pSourceTable = N'libraryInfo_file'
				;

--	3)	INSERT trigger data into labViewStage
	  INSERT	labViewStage.libraryInfo_file
					( ID, HeaderID, FileName, FileRev, Status, HashCode, CreatedDate )
	  SELECT	ID
			  , HeaderID
			  , FileName
			  , FileRev
			  , Status
			  , HashCode
			  , CreatedDate
		FROM	#inserted
				;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	*
												FROM	inserted
														FOR XML PATH( 'pre-process' ), TYPE, ELEMENTS XSINIL
											)
										  , (
											  SELECT	*
												FROM	#inserted
														FOR XML PATH( 'post-process' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'trg_libraryInfo_file' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH