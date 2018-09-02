CREATE TABLE
	labViewStage.LoadHWTVector
		(
			VectorID		int				NOT NULL

		  , CONSTRAINT PK_labViewStage_LoadHWTVector
				PRIMARY KEY CLUSTERED( VectorID ASC )
				WITH( DATA_COMPRESSION = PAGE, IGNORE_DUP_KEY = ON )
				ON [HWTTables]
		)
		ON [HWTTables]
	;
