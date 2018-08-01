  CREATE	TABLE hwt.Equipment
				(
					EquipmentID			int				NOT NULL
				  , Asset				nvarchar(50)	NOT NULL
				  , Description			nvarchar(100)	NOT NULL
				  , CostCenter			nvarchar(50)	NOT NULL
				  , UpdatedBy			sysname			NOT NULL
				  , UpdatedDate			datetime		NOT NULL

				  , CONSTRAINT PK_hwt_Equipment
						PRIMARY KEY CLUSTERED( EquipmentID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				)
			ON [HWTTables]
			;
GO

  CREATE	UNIQUE INDEX UX_hwt_Equipment_Asset
				ON hwt.Equipment
					( Asset ASC, Description ASC, CostCenter ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
