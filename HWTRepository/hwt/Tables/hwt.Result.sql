  CREATE	TABLE hwt.Result
				(
					ResultID	int				NOT NULL
				  , Name		nvarchar(250)	NOT NULL
				  , DataType	nvarchar(50)	NOT NULL
				  , Units		nvarchar(250)	NOT NULL
				  , UpdatedBy	sysname			NOT NULL
				  , UpdatedDate datetime		NOT NULL

				  , CONSTRAINT	PK_hwt_Result
						PRIMARY KEY CLUSTERED( ResultID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				)
			ON [HWTTables]
			;