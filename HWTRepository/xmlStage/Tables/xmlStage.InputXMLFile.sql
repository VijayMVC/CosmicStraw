CREATE TABLE	xmlStage.InputXMLFile
					(
						FileID			uniqueidentifier	NOT NULL
					  , FileName		nvarchar(max)		NOT NULL
					  , FilePath		nvarchar(max)		NOT NULL
					  , HeaderID		int					NOT NULL
					  , FileShredded	datetime2(7)		NOT NULL
					  
					  , CONSTRAINT PK_xmlStage_InputXMLFile
							PRIMARY KEY CLUSTERED( FileID ASC )
							WITH( DATA_COMPRESSION = PAGE )
							ON	[HWTTables]
					)
				ON	[HWTTables]
				TEXTIMAGE_ON [HWTTables]
				;
GO
