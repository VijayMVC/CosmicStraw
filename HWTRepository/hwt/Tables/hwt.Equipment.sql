CREATE TABLE
    hwt.Equipment(
        EquipmentID         int             NOT NULL    IDENTITY
      , Asset               nvarchar(50)    NOT NULL
      , Description         nvarchar(100)   NOT NULL
      , CalibrationDueDate  datetime        NOT NULL
      , CostCenter          nvarchar(50)    NOT NULL
      , HWTChecksum         int             NOT NULL
      , UpdatedBy           sysname         NOT NULL
      , UpdatedDate         datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_Equipment PRIMARY KEY CLUSTERED( EquipmentID ASC ) WITH( DATA_COMPRESSION = PAGE )
	  , CONSTRAINT
			UK_hwt_Equipment_Asset UNIQUE( Asset )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
