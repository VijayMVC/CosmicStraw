  CREATE	TABLE hwt.Element
				(
					ElementID	int				NOT NULL
				  , Name		nvarchar(100)	NOT NULL
				  , DataType	nvarchar(50)	NOT NULL
				  , Units		nvarchar(1000)	NOT NULL
				  , UpdatedBy	sysname			NOT NULL
				  , UpdatedDate datetime		NOT NULL

				  , CONSTRAINT	PK_hwt_Element
						PRIMARY KEY CLUSTERED( ElementID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				)
			ON [HWTTables]
			;
GO

  CREATE	UNIQUE INDEX UX_hwt_Element_Name
				ON hwt.Element
					( Name ASC, DataType ASC, Units ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
