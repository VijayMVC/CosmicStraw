  CREATE	TABLE xmlStage.equipment_element
				(
					ID					int				NOT NULL	IDENTITY
				  , HeaderID			int				NOT NULL
				  , Asset				nvarchar(50)
				  , Description			nvarchar(250)
				  , CalibrationDueDate	nvarchar(50)
				  , CostCenter			nvarchar(50)
				  , NodeOrder			int				NOT NULL	DEFAULT 0
				  , CreatedDate			datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()


				  , CONSTRAINT PK_xmlStage_equipment_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_xmlStage_equipment_element_header
						FOREIGN KEY( HeaderID )
						REFERENCES xmlStage.header( ID )

				)
			ON [HWTTables]
			;
GO

  CREATE	INDEX IX_xmlStage_equipment_element_HeaderID
				ON xmlStage.equipment_element
					( HeaderID ASC )
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			;
GO

  CREATE	INDEX IX_xmlStage_equipment_element_Asset
				ON xmlStage.equipment_element
					( Asset ASC, Description ASC, CostCenter ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;