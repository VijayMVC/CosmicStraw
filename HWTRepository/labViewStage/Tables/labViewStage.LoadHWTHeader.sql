CREATE TABLE
	labViewStage.LoadHWTHeader
		(
			HeaderID		int				NOT NULL

		  , CONSTRAINT PK_labViewStage_LoadHWTHeader
				PRIMARY KEY CLUSTERED( HeaderID ASC )
				WITH( DATA_COMPRESSION = PAGE, IGNORE_DUP_KEY = ON )
				ON [HWTTables]
		)
		ON [HWTTables]
	;
