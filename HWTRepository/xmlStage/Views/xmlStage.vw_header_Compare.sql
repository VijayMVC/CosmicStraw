CREATE VIEW		xmlStage.vw_header_Compare
/*
***********************************************************************************************************************************

		View:	xmlStage.vw_header_Compare
	Abstract:	Returns differences between labViewStage.header and xmlStage.header


	Notes
	-----


	Revision
	--------
	carsoc3		2018-08-31		labVIEW messaging architecture

***********************************************************************************************************************************
*/
AS

  SELECT	TableName = 'labViewStage.header', *
	FROM	(
			  SELECT	ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev, HardwareRev
							, PartSN, OperatorName, TestMode, TestStationID, TestName, TestConfigFile, TestCodePathName
							, TestCodeRev, HWTSysCodeRev, KdrivePath, Comments, ExternalFileInfo, VectorCount
				FROM	labViewStage.header

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
							, TestCodeRev, HWTSysCodeRev, KdrivePath, Comments, ExternalFileInfo, VectorCount
				FROM	labViewStage.header
			) AS x
			;
