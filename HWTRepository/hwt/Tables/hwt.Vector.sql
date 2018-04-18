CREATE TABLE	hwt.Vector
	(
        VectorID        int         NOT NULL
      , HeaderID        int         NOT NULL
      , VectorNumber    int         NOT NULL
      , LoopNumber      int         NOT NULL
      , StartTime       datetime
      , EndTime         datetime
      , HWTChecksum     int         NOT NULL
      , UpdatedBy       sysname     NOT NULL
      , UpdatedDate     datetime    NOT NULL
    
  	  , CONSTRAINT PK_hwt_Vector 
			PRIMARY KEY CLUSTERED( VectorID ASC ) 
				WITH( DATA_COMPRESSION = PAGE )
      
	  , CONSTRAINT FK_hwt_Vector_Header 
			FOREIGN KEY( HeaderID ) 
			REFERENCES hwt.Header( HeaderID )
	  
	  , CONSTRAINT UK_hwt_Vector_Number 
			UNIQUE( HeaderID, VectorNumber, LoopNumber, StartTime )
	) ;
