  CREATE	TABLE hwt.VectorResult
				(
					VectorID			int				NOT NULL
				  , ResultID			int				NOT NULL
				  , NodeOrder			int				NOT NULL
				  , ResultN				int				NOT NULL
				  , ResultValue			nvarchar(250)
				  , UpdatedBy			sysname			NOT NULL
				  , UpdatedDate			datetime		NOT NULL

				  , CONSTRAINT PK_hwt_VectorResult
						PRIMARY KEY CLUSTERED( VectorID ASC, ResultID, NodeOrder ASC, ResultN ASC )
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

  CREATE	INDEX IX_hwt_VectorResult_VectorIDResultID
	  ON	hwt.VectorResult
				( VectorID ASC, ResultID ASC, NodeOrder ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
