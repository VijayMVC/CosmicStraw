CREATE VIEW		xmlStage.vw_libraryInfo_file_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_libraryInfo_file_Compare
	Abstract:	Returns differences between labViewStage.libraryInfo_file and xmlStage.libraryInfo_file


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.libraryInfo_file', *
	FROM	(
			  SELECT	HeaderID, FileName, FileRev, Status, HashCode, NodeOrder
				FROM	labViewStage.libraryInfo_file

			  EXCEPT
			  SELECT	HeaderID, FileName, FileRev, Status, HashCode, NodeOrder
				FROM	xmlStage.libraryInfo_file
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.appConst_element', *
	FROM	(
			  SELECT	HeaderID, FileName, FileRev, Status, HashCode, NodeOrder
				FROM	xmlStage.libraryInfo_file

			  EXCEPT
			  SELECT	HeaderID, FileName, FileRev, Status, HashCode, NodeOrder
				FROM	labViewStage.libraryInfo_file
			) AS x
			;
