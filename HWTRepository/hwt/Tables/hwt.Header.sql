CREATE TABLE
    hwt.Header(
        HeaderID            int             NOT NULL
	  , HeaderIDStr			AS	CONVERT( nvarchar(20), HeaderID ) PERSISTED
      , ResultFileName      nvarchar(1000)  NOT NULL
      , StartTime           datetime        NOT NULL
      , FinishTime          datetime
      , Duration            AS              utility.ufn_GetDuration( StartTime, FinishTime )
      , TestStationName     nvarchar(100)   NOT NULL
      , TestName            nvarchar(250)   NOT NULL
      , TestConfigFile      nvarchar(400)   NOT NULL
      , TestCodePath        nvarchar(400)   NOT NULL
      , TestCodeRevision    nvarchar(100)   NOT NULL
      , HWTSysCodeRevision  nvarchar(100)   NOT NULL
      , KdrivePath          nvarchar(400)   NOT NULL
      , Comments            nvarchar(max)   NOT NULL
      , ExternalFileInfo    nvarchar(max)   NOT NULL
      , HWTChecksum         int             NOT NULL
      , UpdatedBy           sysname         NOT NULL
      , UpdatedDate         datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_Header PRIMARY KEY CLUSTERED( HeaderID ASC ) WITH( DATA_COMPRESSION = PAGE )
	)
;
GO 

CREATE UNIQUE NONCLUSTERED INDEX IX_hwt_Header_HeaderIDString 
	ON hwt.Header( HeaderIDStr ASC ) 
		WITH( DATA_COMPRESSION = PAGE ) 
; 