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

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.libraryInfo_file' ) ;

--	2)	INSERT data into temp storage from PublishAudit
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
					) ;


	  INSERT	INTO #changes
					( ID, HeaderID, FileName, FileRev, Status, HashCode, NodeOrder, OperatorName )
	  SELECT	i.ID
			  , i.HeaderID
			  , i.FileName
			  , i.FileRev
			  , i.Status
			  , i.HashCode
			  , NodeOrder		=	ISNULL( NULLIF( i.NodeOrder, 0 ), i.ID )
			  , h.OperatorName
		FROM	labViewStage.libraryInfo_file AS i
				INNER JOIN	labViewStage.PublishAudit AS pa
						ON	pa.ObjectID = @ObjectID
								AND pa.RecordID = i.ID

				INNER JOIN labViewStage.header AS h
						ON h.ID = i.HeaderID
				;

	IF	( @@ROWCOUNT = 0 )
		RETURN 0 ;


--	2)	INSERT new Library File data from temp storage into hwt.LibraryFile
		--	cte is the set of AppConst data that does not already exist on hwt
		--	newData is the set of data from cte with ID attached
		WITH	cte AS
				(
					  SELECT	FileName
							  , FileRev
							  , Status
							  , HashCode
						FROM	#changes

					  EXCEPT
					  SELECT	FileName
							  , FileRev
							  , Status
							  , HashCode
						FROM	hwt.LibraryFile
				)

			  , newData AS
					(
					  SELECT	DISTINCT
								LibraryFileID	=	MIN( ID ) OVER( PARTITION BY c.FileName, c.FileRev, c.Status, c.HashCode )
							  , FileName		=	cte.FileName
							  , FileRev			=	cte.FileRev
							  , Status			=	cte.Status
							  , HashCode		=	cte.HashCode
						FROM	#changes AS c
								INNER JOIN cte
										ON cte.FileName = c.FileName
											AND cte.FileRev = c.FileRev
											AND cte.Status = c.Status
											AND cte.HashCode = c.HashCode
					)

	  INSERT	hwt.LibraryFile
					( LibraryFileID, FileName, FileRev, Status, HashCode, UpdatedBy, UpdatedDate )
	  SELECT	LibraryFileID	=	newData.LibraryFileID
			  , FileName		=	newData.FileName
			  , FileRev			=	newData.FileRev
			  , Status			=	newData.Status
			  , HashCode		=	newData.HashCode
			  , UpdatedBy		=	x.OperatorName
			  , UpdatedDate		=	SYSDATETIME()
		FROM	newData
				CROSS APPLY
					( SELECT OperatorName FROM #changes AS c WHERE c.ID = newData.LibraryFileID ) AS x
				;


--	3)	Apply LibraryFileID back into temp storage
	  UPDATE	tmp
		 SET	LibraryFileID	=	l.LibraryFileID
		FROM	#changes AS tmp
				INNER JOIN hwt.LibraryFile AS l
						ON l.FileName = tmp.FileName
							AND l.FileRev = tmp.FileRev
							AND l.Status = tmp.Status
							AND l.HashCode = tmp.HashCode
				;


--	4)	INSERT header libraryFile data from temp storage into hwt.HeaderLibraryFile
	  INSERT	hwt.HeaderLibraryFile
					( HeaderID, LibraryFileID, NodeOrder, UpdatedBy, UpdatedDate )
	  SELECT	HeaderID
			  , LibraryFileID
			  , NodeOrder
			  , OperatorName
			  , SYSDATETIME()
		FROM	#changes
				;


--	7)	DELETE processed records from labViewStage.PublishAudit
	  DELETE	pa
		FROM	labViewStage.PublishAudit AS pa
				INNER JOIN	#changes AS tmp
						ON	pa.ObjectID = @ObjectID
							AND tmp.ID = pa.RecordID
				;


	RETURN 0 ;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData	xml ;

	  SELECT	@pErrorData	=	(
								  SELECT	(
											  SELECT	*
												FROM	#changes
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
