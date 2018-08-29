CREATE TABLE
	archive.Tag
		(
			TagID				int				NOT NULL
		  , TagTypeID			int				NOT NULL
		  , Name				nvarchar(50)	NOT NULL
		  , Description			nvarchar(200)	NOT NULL
		  , IsDeleted			tinyint			NOT NULL
		  , UpdatedBy			sysname			NOT NULL
		  , UpdatedDate			datetime2(3)	NOT NULL
		  , VersionNumber		int				NOT NULL
		  , VersionTimestamp	datetime2(3)	NOT NULL

		  , CONSTRAINT	PK_archive_Tag
				PRIMARY KEY CLUSTERED( TagID, VersionNumber )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]
		)
		ON [HWTTables]
		;
