CREATE TABLE
	hwt.Equipment
		(
			EquipmentID			int				NOT NULL	IDENTITY
		  , Asset				nvarchar(50)	NOT NULL
		  , Description			nvarchar(250)	NOT NULL
		  , CostCenter			nvarchar(50)	NOT NULL
		  , CreatedBy			sysname			NOT NULL
		  , CreatedDate			datetime2(3)	NOT NULL

		  , CONSTRAINT PK_hwt_Equipment
				PRIMARY KEY CLUSTERED( EquipmentID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]
		)
		ON [HWTTables]
	;
GO

CREATE UNIQUE INDEX
	UX_hwt_Equipment_Key
		ON		hwt.Equipment( Asset ASC, Description ASC, CostCenter ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
