CREATE TABLE
	hwt.VectorResultValue
		(
			VectorResultID		int				NOT NULL
		  , ResultValue			nvarchar(100)

		  , CONSTRAINT PK_hwt_VectorResultValue
				PRIMARY KEY CLUSTERED( VectorResultID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_hwt_VectorResultValue_VectorResult
				FOREIGN KEY( VectorResultID )
				REFERENCES hwt.VectorResult( VectorResultID )
		)
		ON [HWTTables]
		;
