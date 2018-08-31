CREATE TABLE
	labViewStage.appConst_element
		(
			ID				int				NOT NULL	IDENTITY
		  , HeaderID		int				NOT NULL
		  , Name			nvarchar(250)
		  , Type			nvarchar(50)
		  , Units			nvarchar(250)
		  , Value			nvarchar(1000)
		  , NodeOrder		int				NOT NULL	DEFAULT 0
		  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

		  , CONSTRAINT PK_labViewStage_appConst_element
				PRIMARY KEY CLUSTERED( ID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_labViewStage_appConst_element_header
				FOREIGN KEY( HeaderID )
				REFERENCES labViewStage.header( ID )
		)
		ON [HWTTables]
	;
GO

CREATE INDEX
	IX_labViewStage_appConst_element_HeaderID
		ON		labViewStage.appConst_element( HeaderID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE INDEX
	IX_labViewStage_appConst_element_Name
		ON		labViewStage.appConst_element( Name ASC, Type ASC, Units ASC )
					INCLUDE( HeaderID, NodeOrder )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
