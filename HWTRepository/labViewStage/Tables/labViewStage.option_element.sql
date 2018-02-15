﻿CREATE TABLE
    labViewStage.option_element(
        ID          int             NOT NULL    IDENTITY
      , HeaderID    int             NOT NULL
      , Name        nvarchar(100)
      , Type        nvarchar(50)
      , Units       nvarchar(50)
      , Value       nvarchar(1000)
      , CONSTRAINT 
			PK_labViewStage_option_element PRIMARY KEY CLUSTERED( ID ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT 
			FK_labViewStage_option_element_header FOREIGN KEY( HeaderID ) REFERENCES labViewStage.header( ID )
    )
;
