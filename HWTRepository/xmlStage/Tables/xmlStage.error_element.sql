CREATE TABLE
    xmlStage.error_element(
        ID              int             NOT NULL    IDENTITY
      , VectorID        int             NOT NULL
      , ErrorCode       int             NOT NULL
      , ErrorText       nvarchar(max)   NOT NULL
      , CONSTRAINT 
			PK_xmlStage_error_element PRIMARY KEY CLUSTERED( ID ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT 
			FK_xmlStage_error_element_vector FOREIGN KEY( VectorID ) REFERENCES xmlStage.vector( ID )
    )
;
