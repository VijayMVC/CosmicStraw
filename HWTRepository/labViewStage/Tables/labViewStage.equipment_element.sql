CREATE TABLE
    labViewStage.equipment_element (
        ID                  int             NOT NULL    IDENTITY
      , HeaderID            int             NOT NULL
      , Description         nvarchar(100)
      , Asset               nvarchar(50)
      , CalibrationDueDate  nvarchar(50)
      , CostCenter          nvarchar(50)
      , CONSTRAINT 
			PK_labViewStage_equipment_element PRIMARY KEY CLUSTERED( ID ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT 
			FK_labViewStage_equipment_element_header FOREIGN KEY( HeaderID ) REFERENCES labViewStage.header( ID )
    )
;
