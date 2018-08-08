﻿  CREATE	TABLE labViewStage.equipment_element
				(
					ID					int				NOT NULL	IDENTITY
				  , HeaderID			int				NOT NULL
				  , Description			nvarchar(100)
				  , Asset				nvarchar(50)
				  , CalibrationDueDate	nvarchar(50)
				  , CostCenter			nvarchar(50)
				  , NodeOrder			int				NOT NULL	DEFAULT 0
				  , CreatedDate			datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_labViewStage_equipment_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_labViewStage_equipment_element_header
						FOREIGN KEY( HeaderID )
						REFERENCES labViewStage.header( ID )

				)
			ON [HWTTables]
			;
GO

  CREATE	INDEX IX_labViewStage_equipment_element_HeaderID
				ON labViewStage.equipment_element
					( HeaderID ASC )
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			; 