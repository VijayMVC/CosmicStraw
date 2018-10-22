CREATE	VIEW xmlStage.vw_header_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_header_Compare
	Abstract:	Returns differences between labViewStage.header and xmlStage.header

	Notes
	-----

	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture
	carsoc3		2018-10-04		Revision -- Transform data in repository, accounting for differences in LabVIEW outputs

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.header', *
	FROM	(
			  SELECT	ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev
							, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile, TestCodePathName
							, TestCodeRev, HWTSysCodeRev, KdrivePath
							, Comments = REPLACE( REPLACE( h.Comments, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
							, ExternalFileInfo = REPLACE( REPLACE( h.ExternalFileInfo, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
							, VectorCount
				FROM	labViewStage.header AS h

			  EXCEPT
			  SELECT	ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev
							, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile, TestCodePathName
							, TestCodeRev, HWTSysCodeRev, KdrivePath, Comments, ExternalFileInfo, VectorCount
				FROM	xmlStage.header
			) AS x

  UNION ALL
  SELECT	TableName = 'xmlStage.header', *
	FROM	(
			  SELECT	ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev
							, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile, TestCodePathName
							, TestCodeRev, HWTSysCodeRev, KdrivePath, Comments, ExternalFileInfo, VectorCount
				FROM	xmlStage.header

			  EXCEPT
			  SELECT	ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev
							, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile, TestCodePathName
							, TestCodeRev, HWTSysCodeRev, KdrivePath
							, Comments = REPLACE( REPLACE( h.Comments, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
							, ExternalFileInfo = REPLACE( REPLACE( h.ExternalFileInfo, NCHAR(13)+ NCHAR(10), NCHAR(10) ), NCHAR(13), NCHAR(10) )
							, VectorCount
				FROM	labViewStage.header AS h
			) AS x
;
