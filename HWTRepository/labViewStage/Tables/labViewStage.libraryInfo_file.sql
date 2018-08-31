CREATE TABLE
	labViewStage.libraryInfo_file
		(
			ID				int				NOT NULL	IDENTITY
		  , HeaderID		int				NOT NULL
		  , FileName		nvarchar(400)
		  , FileRev			nvarchar(50)
		  , Status			nvarchar(50)
		  , HashCode		nvarchar(100)
		  , NodeOrder		int				NOT NULL	DEFAULT 0
		  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

		  , CONSTRAINT PK_labViewStage_libraryInfo_file
				PRIMARY KEY CLUSTERED( ID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_labViewStage_libraryInfo_file_header
				FOREIGN KEY( HeaderID )
				REFERENCES labViewStage.header( ID )
		)
		ON	[HWTTables]
	;
GO

CREATE INDEX
	IX_labViewStage_libraryInfo_file_LibraryFileKey
		ON		labViewStage.libraryInfo_file
					(
						FileName ASC, FileRev ASC, Status ASC, HashCode ASC
					)
					INCLUDE( HeaderID, NodeOrder )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
