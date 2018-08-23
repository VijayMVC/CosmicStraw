  CREATE	TABLE hwt.VectorResultExtended
				(
					VectorResultID 		int				NOT NULL
				  , ResultValue			nvarchar(max)

				  , CONSTRAINT PK_hwt_VectorResultExtended
						PRIMARY KEY CLUSTERED( VectorResultID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_hwt_VectorResultExtended_VectorResult
						FOREIGN KEY( VectorResultID )
						REFERENCES hwt.VectorResult( VectorResultID )
				)
			ON [HWTTables]
			TEXTIMAGE_ON [HWTTables]
			;

