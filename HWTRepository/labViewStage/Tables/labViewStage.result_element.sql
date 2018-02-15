CREATE TABLE
    labViewStage.result_element(
        ID          int             NOT NULL         IDENTITY
      , VectorID    int             NOT NULL
      , Name        nvarchar(100)
      , Type        nvarchar(50)
      , Units       nvarchar(50)
      , Value       nvarchar(max)
      , CONSTRAINT 
			PK_labViewStage_result_element PRIMARY KEY CLUSTERED( ID ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT 
			FK_labViewStage_result_element_vector FOREIGN KEY( VectorID ) REFERENCES labViewStage.vector( ID )
    )
;
