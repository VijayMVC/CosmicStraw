  CREATE	TABLE hwt.VectorError
				(
					VectorErrorID			int				NOT NULL
				  , VectorID				int				NOT NULL
				  , ErrorType				int				NOT NULL
						--	ErrorType 1:  test error
						--	ErrorType 2:  data error
						--	ErrorType 3:  input parameter error

				  , ErrorCode				int				NOT NULL
				  , ErrorText				nvarchar(max)	NOT NULL
				  , ErrorSequenceNumber		int				NOT NULL
				  , UpdatedBy				sysname			NOT NULL
				  , UpdatedDate				datetime		NOT NULL

				  , CONSTRAINT	PK_hwt_VectorError
						PRIMARY KEY CLUSTERED( VectorErrorID ASC )
						WITH( DATA_COMPRESSION = PAGE )
							ON [HWTTables]

				  , CONSTRAINT	FK_hwt_VectorError_Vector
						FOREIGN KEY( VectorID )
						REFERENCES hwt.Vector( VectorID )

				  , CONSTRAINT	CK_hwt_VectorError_ErrorType
						CHECK( ErrorType IN ( 1, 2, 3 ) )
				)
			ON [HWTTables]
			TEXTIMAGE_ON [HWTTables]
			;
GO

  CREATE	INDEX IX_hwt_VectorError_VectorData
	  ON	hwt.VectorError
				( VectorID ASC )
			INCLUDE
				( ErrorCode, ErrorText )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;


