CREATE PROCEDURE
	hwt.usp_LoadLibraryFileFromStage
		(
			@pHeaderXML		xml
		)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_LoadLibraryFileFromStage
	Abstract:	Load libraryFile data from stage to hwt.LibraryFile and hwt.HeaderLibraryFile

	Logic Summary
	-------------
	1)	EXECUTE sp_getapplock to ensure single-threading for procedure
	2)	INSERT data into temp storage from trigger
	3)	INSERT new LibraryFile data from temp storage into hwt.LibraryFile
	4)	UPDATE LibraryFileID back into temp storage
	5)	INSERT header LibraryFile data from temp storage into hwt.HeaderLibraryFile
	6)	UPDATE PublishDate on labViewStage.libraryInfo_file
	7)	EXECUTE sp_releaseapplock to release lock


	Parameters
	----------

	Notes
	-----

	Revision
	--------
	carsoc3		2018-04-27		production release
	carsoc3		2018-08-31		enhanced error handling
								updated messaging architecture
									--	extract all records not published
									--	publish to hwt
									--	update stage data with publish date

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@loadHeader		TABLE	( HeaderID	int ) ;
	 DECLARE	@lvsRecord		TABLE	( RecordID	int ) ;


--	1)	SELECT the HeaderIDs that need to be published

	  INSERT	@loadHeader( HeaderID )
	  SELECT	loadHeader.xmlData.value( '@value[1]', 'int' )
		FROM	@pHeaderXML.nodes('LoadHeader/HeaderID') AS loadHeader(xmlData)
				;


--	2)	SELECT the labViewStage records that need to be published
	  INSERT	@lvsRecord( RecordID )
	  SELECT	ID
		FROM	labViewStage.libraryInfo_file AS lvs
				INNER JOIN	@loadHeader AS h
						ON	h.HeaderID = lvs.HeaderID
				;

	IF	( @@ROWCOUNT = 0 ) RETURN ;


--	2)	INSERT new Library File data from temp storage into hwt.LibraryFile
	  INSERT	hwt.LibraryFile
					( FileName, FileRev, Status, HashCode, CreatedBy, CreatedDate )
	  SELECT	DISTINCT
				FileName		=	lvs.FileName
			  , FileRev			=	lvs.FileRev
			  , Status			=	lvs.Status
			  , HashCode		=	lvs.HashCode
			  , CreatedBy		=	FIRST_VALUE( h.OperatorName ) OVER	(
																			PARTITION BY	lvs.FileName
																						  , lvs.FileRev
																						  , lvs.Status
																						  , lvs.HashCode
																			ORDER BY		lvs.ID
																		)

			  , CreatedDate		=	SYSDATETIME()
		FROM	labViewStage.libraryInfo_file AS lvs
				INNER JOIN	@lvsRecord
						ON	RecordID = lvs.ID

				INNER JOIN	labViewStage.header AS h
						ON	h.ID = lvs.HeaderID

	   WHERE	NOT EXISTS
					(
					  SELECT	1
						FROM	hwt.LibraryFile AS lf
					   WHERE	lf.FileName = lvs.FileName
								AND lf.FileRev = lvs.FileRev
								AND lf.Status = lvs.Status
								AND lf.HashCode = lvs.HashCode
					)
				;


--	4)	INSERT header libraryFile data from temp storage into hwt.HeaderLibraryFile
	  INSERT	hwt.HeaderLibraryFile
					( HeaderID, LibraryFileID, NodeOrder )
	  SELECT	i.HeaderID
			  , lf.LibraryFileID
			  , i.NodeOrder
		FROM	labViewStage.libraryInfo_file AS i
				INNER JOIN	@lvsRecord
						ON	RecordID = i.ID

				INNER JOIN	hwt.LibraryFile AS lf
						ON	lf.FileName = i.FileName
								AND lf.FileRev = i.FileRev
								AND lf.Status = i.Status
								AND lf.HashCode = i.HashCode

	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData	xml ;

	  SELECT	@pErrorData	=	(
								  SELECT	(
											  SELECT	i.*
												FROM	labViewStage.libraryInfo_file AS i
														INNER JOIN	@lvsRecord
																ON	RecordID = i.ID
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadLibraryFileFromStage' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pErrorData
				;

	RETURN 55555 ;

END CATCH
