CREATE TABLE
    labViewStage.vector(
        ID          int             NOT NULL    IDENTITY
      , HeaderID    int             NOT NULL
      , VectorNum   int             NOT NULL
      , Loop        int             NOT NULL    CONSTRAINT DF_labViewStage_vector_Loop  DEFAULT 0
	  , ReqID		nvarchar(1000)	
      , StartTime   nvarchar(50)
      , EndTime     nvarchar(50)
      , CONSTRAINT
            PK_labViewStage_vector PRIMARY KEY CLUSTERED( ID ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT
            FK_labViewStage_vector_header FOREIGN KEY( HeaderID ) REFERENCES labViewStage.header( ID )
      , CONSTRAINT
            UX_labViewStage_VectorNum UNIQUE ( HeaderID, VectorNum, Loop, StartTime )
    )
;
