CREATE TABLE
	hwt.LibraryFile
		(
			LibraryFileID	int				NOT NULL	IDENTITY
		  , FileName		nvarchar(400)	NOT NULL
		  , FileRev			nvarchar(50)	NOT NULL
		  , Status			nvarchar(50)	NOT NULL
		  , HashCode		nvarchar(100)
		  , CreatedBy		sysname			NOT NULL
		  , CreatedDate		datetime2(3)	NOT NULL

		  , CONSTRAINT	PK_hwt_LibraryFile
				PRIMARY KEY CLUSTERED( LibraryFileID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]
		)
		ON [HWTTables]
	;
GO

CREATE UNIQUE INDEX
	UX_hwt_LibraryFile_Key
		ON hwt.LibraryFile
				(
					FileName ASC, FileRev ASC, Status ASC, HashCode ASC
				)
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
