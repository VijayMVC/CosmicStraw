CREATE TABLE
	labViewStage.PublishAudit
		(
			ObjectID		int				NOT NULL
		  , RecordID		int				NOT NULL

		  , CONSTRAINT PK_labViewStage_PublishAudit
				PRIMARY KEY CLUSTERED( ObjectID ASC, RecordID ASC )
				WITH( DATA_COMPRESSION = PAGE, IGNORE_DUP_KEY = ON )
				ON [HWTTables]
		)
		ON [HWTTables]
	;
