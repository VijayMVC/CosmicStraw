CREATE TABLE
    labViewStage.appConst_element(
        ID          int             NOT NULL    IDENTITY
      , HeaderID    int             NOT NULL
      , Name        nvarchar(100)
      , Type        nvarchar(50)
      , Units       nvarchar(50)
      , Value       nvarchar(1000)
      , CONSTRAINT 
			PK_labViewStage_appConst_element PRIMARY KEY CLUSTERED( ID ASC )
      , CONSTRAINT 
			FK_labViewStage_appConst_element_header  FOREIGN KEY( HeaderID ) REFERENCES labViewStage.header( ID )
    )
;
