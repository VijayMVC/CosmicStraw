  CREATE	TABLE xmlStage.libraryInfo_file
				(
					ID				int				NOT NULL	IDENTITY
				  , HeaderID		int				NOT NULL
				  , FileName		nvarchar(400)
				  , FileRev			nvarchar(50)
				  , Status			nvarchar(50)
				  , HashCode		nvarchar(100)
				  , NodeOrder		int				NOT NULL	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_xmlStage_libraryInfo_file
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_xmlStage_libraryInfo_file_header
						FOREIGN KEY( HeaderID )
						REFERENCES xmlStage.header( ID )
				)
			ON	[HWTTables]
			;
GO

  CREATE 	INDEX IX_xmlStage_libraryInfo_file_Name 
				ON xmlStage.libraryInfo_file
					( FileName ASC, FileRev ASC, Status ASC, HashCode ASC ) 
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON 	[HWTIndexes]
			; 