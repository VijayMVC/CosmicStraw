  CREATE	TABLE hwt.HeaderLibraryFile
				(
					HeaderID		int			NOT NULL
				  , LibraryFileID	int			NOT NULL
				  , NodeOrder		int			NOT NULL
				  , UpdatedBy		sysname		NOT NULL
				  , UpdatedDate		datetime	NOT NULL

				  , CONSTRAINT	PK_hwt_HeaderLibraryFile
						PRIMARY KEY CLUSTERED( HeaderID ASC, LibraryFileID ASC )
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
