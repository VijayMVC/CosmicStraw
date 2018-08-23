  CREATE	TABLE hwt.[Option]
				(
					OptionID	int				NOT NULL	IDENTITY
				  , Name		nvarchar(250)	NOT NULL
				  , DataType	nvarchar(50)	NOT NULL
				  , Units		nvarchar(250)	NOT NULL
				  , UpdatedBy	sysname			NOT NULL
				  , UpdatedDate datetime2(3)	NOT NULL

				  , CONSTRAINT PK_hwt_Option
						PRIMARY KEY CLUSTERED( OptionID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				)
			ON [HWTTables]
			;
GO

  CREATE	UNIQUE INDEX UX_hwt_Option_Name
				ON hwt.[Option]
					( Name ASC, DataType ASC, Units ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
