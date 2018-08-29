CREATE TABLE
	archive.Header
		(
			HeaderID			int				NOT NULL
		  , ResultFileName		nvarchar(1000)	NOT NULL
		  , StartTime			datetime2(3)	NOT NULL
		  , FinishTime			datetime2(3)
		  , Duration			nvarchar(50)	NOT NULL
		  , TestStationName		nvarchar(100)	NOT NULL
		  , TestName			nvarchar(250)	NOT NULL
		  , TestConfigFile		nvarchar(400)	NOT NULL
		  , TestCodePath		nvarchar(400)	NOT NULL
		  , TestCodeRevision	nvarchar(100)	NOT NULL
		  , HWTSysCodeRevision	nvarchar(100)	NOT NULL
		  , KdrivePath			nvarchar(400)	NOT NULL
		  , Comments			nvarchar(max)	NOT NULL
		  , ExternalFileInfo	nvarchar(max)	NOT NULL
		  , UpdatedBy			sysname			NOT NULL
		  , UpdatedDate			datetime2(3)	NOT NULL
		  , VersionNumber		int				NOT NULL
		  , VersionTimestamp	datetime2(3)	NOT NULL

		  , CONSTRAINT PK_archive_Header
				PRIMARY KEY CLUSTERED
					(
						HeaderID ASC, VersionNumber ASC
					)
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]
		)
		ON	[HWTTables]
		TEXTIMAGE_ON [HWTTables]
		;
