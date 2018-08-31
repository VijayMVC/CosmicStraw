CREATE TABLE
	hwt.VectorResult
		(
			VectorResultID		int				NOT NULL	IDENTITY
		  , VectorID			int				NOT NULL
		  , ResultID			int				NOT NULL
		  , NodeOrder			int				NOT NULL
		  , IsArray				bit				NOT NULL	DEFAULT 0
		  , IsExtended			bit				NOT NULL	DEFAULT 0

		  , CONSTRAINT PK_hwt_VectorResult
				PRIMARY KEY CLUSTERED( VectorResultID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_hwt_VectorResult_Result
				FOREIGN KEY( ResultID )
				REFERENCES hwt.Result( ResultID )

		  , CONSTRAINT FK_hwt_VectorResult_Vector
				FOREIGN KEY( VectorID )
				REFERENCES hwt.Vector( VectorID )
		)
		ON [HWTTables]
	;
GO

CREATE UNIQUE INDEX
	UX_hwt_VectorResult_Key
		ON hwt.VectorResult
			( VectorID ASC, ResultID ASC, NodeOrder ASC )
			INCLUDE( IsArray, IsExtended )
		WITH ( DATA_COMPRESSION = PAGE )
		ON [HWTIndexes]
	;
GO

CREATE INDEX
	IX_hwt_VectorResult_VectorID
		ON		hwt.VectorResult( VectorID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE INDEX
	IX_hwt_VectorResult_ResultID
		ON		hwt.VectorResult( ResultID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;