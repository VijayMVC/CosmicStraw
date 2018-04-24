  CREATE 	TABLE hwt.TestError
			(	        
				TestErrorID int             NOT NULL    IDENTITY
			  , VectorID    int             NOT NULL
			  , ErrorCode   int             NOT NULL
			  , ErrorText   nvarchar(max)   NOT NULL
			  , UpdatedBy   sysname         NOT NULL
			  , UpdatedDate datetime        NOT NULL
			  
			  , CONSTRAINT 	PK_hwt_TestError 
					PRIMARY KEY CLUSTERED( TestErrorID ASC ) 
					WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]
				
			  , CONSTRAINT  FK_hwt_TestError_Vector 
					FOREIGN KEY( VectorID ) 
					REFERENCES hwt.Vector( VectorID )
			) 	ON [HWTTables]
			TEXTIMAGE_ON [HWTTables]
			;
GO

  CREATE 	INDEX IX_hwt_TestError_VectorError 
	  ON 	hwt.TestError
				( VectorID ASC )
			INCLUDE	
				( ErrorCode, ErrorText )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;

	
