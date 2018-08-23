  CREATE	TABLE xmlStage.appConst_element
				(
					ID				int				NOT NULL	IDENTITY
				  , HeaderID		int				NOT NULL
				  , Name			nvarchar(250)
				  , Type			nvarchar(50)
				  , Units			nvarchar(250)
				  , Value			nvarchar(1000)
				  , NodeOrder		int				NOT NULL	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_xmlStage_appConst_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_xmlStage_appConst_element_header
						FOREIGN KEY( HeaderID )
						REFERENCES xmlStage.header( ID )
				)
			ON [HWTTables]
			;
GO

  CREATE	INDEX IX_xmlStage_appConst_element_HeaderID
				ON xmlStage.appConst_element
					( HeaderID ASC )
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			;
GO

  CREATE	INDEX IX_xmlStage_appConst_element_Name
				ON xmlStage.appConst_element
					( Name ASC, Type ASC, Units ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
