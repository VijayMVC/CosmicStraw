CREATE TABLE
	archive.HeaderTag
		(
			HeaderID			int				NOT NULL
		  , TagID				int				NOT NULL
		  , Notes				nvarchar(200)	NOT NULL
		  , UpdatedBy			sysname			NOT NULL
		  , UpdatedDate			datetime		NOT NULL
		  , VersionNumber		int				NOT NULL
		  , VersionTimestamp	datetime2(3)	NOT NULL

		  , CONSTRAINT	PK_archive_HeaderTag
				PRIMARY KEY CLUSTERED( HeaderID, TagID, VersionNumber )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]
		)
		ON [HWTTables]
		;
