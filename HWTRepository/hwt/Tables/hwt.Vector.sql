  CREATE	TABLE hwt.Vector
				(
					VectorID		int			NOT NULL
				  , HeaderID		int			NOT NULL
				  , VectorNumber	int			NOT NULL
				  , LoopNumber		int			NOT NULL
				  , StartTime		datetime
				  , EndTime			datetime
				  , UpdatedBy		sysname		NOT NULL
				  , UpdatedDate		datetime	NOT NULL

				  , CONSTRAINT PK_hwt_Vector
						PRIMARY KEY CLUSTERED( VectorID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_hwt_Vector_Header
						FOREIGN KEY( HeaderID )
						REFERENCES hwt.Header( HeaderID )

				)
			ON [HWTTables]
			;
GO

  CREATE	UNIQUE INDEX UX_hwt_Vector_Number
				ON hwt.Vector
					( HeaderID ASC, VectorNumber ASC, LoopNumber ASC, StartTime ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
