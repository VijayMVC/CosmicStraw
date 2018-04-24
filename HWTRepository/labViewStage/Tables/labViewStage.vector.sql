CREATE TABLE	labViewStage.vector
	(
        ID          int             NOT NULL    
      , HeaderID    int             NOT NULL
      , VectorNum   int             NOT NULL
      , Loop        int             NOT NULL    DEFAULT 0
	  , ReqID		nvarchar(1000)	
      , StartTime   nvarchar(50)
      , EndTime     nvarchar(50)
	  , CreatedDate	datetime					DEFAULT GETDATE()
	  
      , CONSTRAINT PK_labViewStage_vector 
			PRIMARY KEY CLUSTERED( ID ) 
			WITH( DATA_COMPRESSION = PAGE ) 
			ON [HWTTables]
				
      , CONSTRAINT FK_labViewStage_vector_header 
			FOREIGN KEY( HeaderID ) 
			REFERENCES labViewStage.header( ID )
		)	ON	[HWTTables]
				;
GO 
  
CREATE INDEX 	UX_labViewStage_vector_number
		  ON 	labViewStage.vector
					( HeaderID ASC, VectorNum ASC, Loop ASC, StartTime ASC ) 
		WITH	( DATA_COMPRESSION = PAGE ) 
		  ON	[HWTIndexes]
				;
