CREATE TABLE	labViewStage.libraryInfo_file
				(
					ID          int             NOT NULL
				  , HeaderID    int             NOT NULL
				  , FileName    nvarchar(400)
				  , FileRev     nvarchar(50)
				  , Status      nvarchar(50)
				  , HashCode    nvarchar(100)
				  , CreatedDate datetime					DEFAULT GETDATE()
				  
				  , CONSTRAINT PK_labViewStage_libraryInfo_file 
						PRIMARY KEY CLUSTERED( ID ASC ) 
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]
				
				  , CONSTRAINT FK_labViewStage_libraryInfo_file_header 
						FOREIGN KEY( HeaderID ) 
						REFERENCES labViewStage.header( ID )
				)	ON	[HWTTables]
				;
