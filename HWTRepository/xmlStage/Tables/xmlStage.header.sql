﻿CREATE TABLE
    xmlStage.header(
        ID                  int             NOT NULL    IDENTITY( 500000, 1 )
      , ResultFile          nvarchar(1000)
      , StartTime           nvarchar(100)
      , FinishTime          nvarchar(100)
      , TestDuration        nvarchar(100)
      , ProjectName         nvarchar(100)
      , FirmwareRev         nvarchar(100)
      , HardwareRev         nvarchar(100)
      , PartSN              nvarchar(100)
      , OperatorName        nvarchar(100)
      , TestMode            nvarchar(50)
      , TestStationID       nvarchar(100)
      , TestName            nvarchar(250)
      , TestConfigFile      nvarchar(400)
      , TestCodePathName    nvarchar(400)
      , TestCodeRev         nvarchar(100)
      , HWTSysCodeRev       nvarchar(100)
      , KdrivePath          nvarchar(400)
      , Comments            nvarchar(max)
      , ExternalFileInfo    nvarchar(max)
      , CONSTRAINT 
			PK_xmlStage_header PRIMARY KEY CLUSTERED( ID ASC ) WITH( DATA_COMPRESSION = PAGE )
    )
;
