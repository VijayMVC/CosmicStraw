CREATE TABLE
	hwt.HeaderOption
		(
			HeaderID	int				NOT NULL
		  , OptionID	int				NOT NULL
		  , NodeOrder	int				NOT NULL
		  , OptionValue	nvarchar(1000)	NOT NULL

		  , CONSTRAINT	PK_hwt_HeaderOption
				PRIMARY KEY CLUSTERED( HeaderID ASC, OptionID ASC, NodeOrder ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT	FK_hwt_HeaderOption_Header
				FOREIGN KEY( HeaderID )
				REFERENCES hwt.Header( HeaderID )

		  , CONSTRAINT	FK_hwt_HeaderOption_Option
				FOREIGN KEY( OptionID )
				REFERENCES hwt.[Option]( OptionID )
		)
		ON [HWTTables]
	;
GO

CREATE INDEX
	IX_hwt_HeaderOption_HeaderID
		ON		hwt.HeaderOption( HeaderID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE INDEX
	IX_hwt_HeaderOption_OptionID
		ON		hwt.HeaderOption( OptionID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
