  CREATE	TABLE hwt.HeaderEquipment
				(
					HeaderID			int			NOT NULL
				  , EquipmentID			int			NOT NULL
				  , NodeOrder			int			NOT NULL
				  , CalibrationDueDate	datetime	NOT NULL
				  , UpdatedBy			sysname		NOT NULL
				  , UpdatedDate			datetime	NOT NULL

				  , CONSTRAINT	PK_hwt_HeaderEquipment
						PRIMARY KEY CLUSTERED( HeaderID ASC, EquipmentID ASC, NodeOrder ASC )
						WITH( DATA_COMPRESSION = PAGE ) ON [HWTTables]

				  , CONSTRAINT	FK_hwt_HeaderEquipment_Equipment
						FOREIGN KEY( EquipmentID )
						REFERENCES hwt.Equipment( EquipmentID )

				  , CONSTRAINT	FK_hwt_HeaderEquipment_Header
						FOREIGN KEY( HeaderID )
						REFERENCES hwt.Header( HeaderID )
				)
			ON [HWTTables]
			;
