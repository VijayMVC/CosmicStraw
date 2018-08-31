CREATE TABLE
	hwt.HeaderLibraryFile
		(
			HeaderID		int				NOT NULL
		  , LibraryFileID	int				NOT NULL
		  , NodeOrder		int				NOT NULL

		  , CONSTRAINT	PK_hwt_HeaderLibraryFile
				PRIMARY KEY CLUSTERED( HeaderID ASC, LibraryFileID ASC, NodeOrder ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT	FK_hwt_HeaderLibraryFile_Header
				FOREIGN KEY( HeaderID )
				REFERENCES hwt.Header( HeaderID )

		  , CONSTRAINT	FK_hwt_HeaderLibraryFile_LibraryFile
				FOREIGN KEY( LibraryFileID )
				REFERENCES hwt.LibraryFile( LibraryFileID )

		)
		ON [HWTTables]
	;
GO

CREATE INDEX
	IX_hwt_HeaderLibraryFile_HeaaderID
		ON		hwt.HeaderLibraryFile( HeaderID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE INDEX
	IX_hwt_HeaderLibraryFile_LibraryFileID
		ON		hwt.HeaderLibraryFile( LibraryFileID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
