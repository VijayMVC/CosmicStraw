CREATE TABLE
    xmlStage.vector(
        ID          int             NOT NULL    IDENTITY( 50000001, 1 )
      , HeaderID    int             NOT NULL
      , VectorNum   int             NOT NULL
      , Loop        int             NOT NULL    CONSTRAINT DF_xmlStage_vector_Loop  DEFAULT 0
	  , ReqID		nvarchar(1000)
      , StartTime   nvarchar(50)
      , EndTime     nvarchar(50)
      , CONSTRAINT 
			PK_xmlStage_vector PRIMARY KEY CLUSTERED( ID ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT 
			FK_xmlStage_vector_header FOREIGN KEY( HeaderID ) REFERENCES xmlStage.header( ID )
      , CONSTRAINT 
			UX_xmlStage_VectorNum UNIQUE ( HeaderID, VectorNum, Loop, StartTime )
    )
;
