CREATE TABLE
	archive.labViewStage_header
		(
			ID					int				NOT NULL
		  , ResultFile			nvarchar(1000)
		  , StartTime			nvarchar(100)
		  , FinishTime			nvarchar(100)
		  , TestDuration		nvarchar(100)
		  , ProjectName			nvarchar(100)
		  , FirmwareRev			nvarchar(100)
		  , HardwareRev			nvarchar(100)
		  , PartSN				nvarchar(100)
		  , OperatorName		nvarchar(100)
		  , TestMode			nvarchar(50)
		  , TestStationID		nvarchar(100)
		  , TestName			nvarchar(250)
		  , TestConfigFile		nvarchar(400)
		  , TestCodePathName	nvarchar(400)
		  , TestCodeRev			nvarchar(100)
		  , HWTSysCodeRev		nvarchar(100)
		  , KdrivePath			nvarchar(400)
		  , Comments			nvarchar(max)
		  , ExternalFileInfo	nvarchar(max)
		  , IsLegacyXML			int
		  , VectorCount			int
		  , CreatedDate			datetime2(3)	NOT NULL
		  , UpdatedDate			datetime2(3)
		  , VersionNumber		int				NOT NULL
		  , VersionTimestamp	datetime2(3)	NOT NULL

		  , CONSTRAINT	PK_labViewStage_header
				PRIMARY KEY CLUSTERED( ID ASC, VersionNumber ASC)
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		)
		ON	[HWTTables]
		TEXTIMAGE_ON [HWTTables]
		;
GO

CREATE INDEX
	IX_labViewStage_header_OperatorName
		ON labViewStage.header
			( OperatorName ASC )

		WITH( DATA_COMPRESSION = PAGE )
		ON [HWTIndexes]
		;
