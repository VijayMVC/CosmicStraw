CREATE TABLE	xmlStage.XMLOutputCache
					(
						HeaderID		int					NOT NULL
					  , FileName		nvarchar( 1000 ) 
					  , DatasetXML		xml( CONTENT xmlStage.LabViewXSD ) 
					  , DatasetCached	datetime2(3)		NOT NULL	DEFAULT SYSDATETIME()
					  
					  , CONSTRAINT PK_xmlStage_XMLOutputCache
							PRIMARY KEY CLUSTERED( HeaderID ASC )
							WITH( DATA_COMPRESSION = PAGE )
							ON	[HWTTables]
					)
				ON	[HWTTables]
				TEXTIMAGE_ON [HWTTables]
				;

