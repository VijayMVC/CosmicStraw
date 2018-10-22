CREATE PROCEDURE	hwt.usp_LoadLibraryFileFromStage
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

SET XACT_ABORT, NOCOUNT ON 
;
BEGIN TRY
	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.libraryInfo_file' ) 
;
	 DECLARE 	@Records	TABLE	( RecordID int ) 
;
	 
--	1)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	labViewStage.PublishAudit
	  OUTPUT 	deleted.RecordID 	  
	    INTO	@Records( RecordID ) 
	   WHERE 	ObjectID = @ObjectID
;
	IF	( @@ROWCOUNT = 0 )
		RETURN 0 
;
		
--	2)	INSERT new Library File data from temp storage into hwt.LibraryFile
	  INSERT	hwt.LibraryFile
					( FileName, FileRev, Status, HashCode, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT 
	  		    FileName		=	lvs.FileName
			  , FileRev			=	lvs.FileRev
			  , Status			=	lvs.Status
			  , HashCode		=	lvs.HashCode
			  , UpdatedBy		=	FIRST_VALUE( h.OperatorName ) OVER	( 	
																			PARTITION BY	lvs.FileName
																						  , lvs.FileRev
																						  , lvs.Status
																						  , lvs.HashCode 
																			ORDER BY 		lvs.ID 
																		)
																		
			  , UpdatedDate		=	SYSDATETIME()
		FROM	labViewStage.libraryInfo_file AS lvs
				INNER JOIN	@Records
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

--	3)	INSERT data into temp storage from PublishAudit
	CREATE TABLE	#changes
					(
						ID				int
					  , HeaderID		int
					  , FileName		nvarchar(400)
					  , FileRev			nvarchar(50)
					  , Status			nvarchar(50)
					  , HashCode		nvarchar(100)
					  , OperatorName	nvarchar(50)
					  , NodeOrder		int
					  , LibraryFileID	int
					) 
;
	  INSERT	INTO #changes
					( ID, HeaderID, FileName, FileRev, Status, HashCode, NodeOrder, OperatorName, LibraryFileID )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.FileName
			  , i.FileRev
			  , i.Status
			  , i.HashCode
			  , i.NodeOrder		
			  , h.OperatorName
			  , lf.LibraryFileID
		FROM	labViewStage.libraryInfo_file AS i
				INNER JOIN	@Records 
						ON	RecordID = i.ID

				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID

				INNER JOIN	hwt.LibraryFile AS lf
						ON	lf.FileName = i.FileName
								AND lf.FileRev = i.FileRev
								AND lf.Status = i.Status
								AND lf.HashCode = i.HashCode
;

--	4)	INSERT header libraryFile data from temp storage into hwt.HeaderLibraryFile
	  INSERT	hwt.HeaderLibraryFile
					( HeaderID, LibraryFileID, NodeOrder, UpdatedBy, UpdatedDate )
	  SELECT	DISTINCT 
				HeaderID
			  , LibraryFileID
			  , NodeOrder
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
;
	RETURN 0 
;

END TRY
BEGIN CATCH
	 DECLARE	@pErrorData	xml 
;
	  SELECT	@pErrorData	=	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
														FOR XML PATH( 'changes' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'usp_LoadLibraryFileFromStage' ), TYPE
								)
;
	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION 
;
	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData	=	@pErrorData
;
	RETURN 55555 
;
END CATCH
