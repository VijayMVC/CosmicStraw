  CREATE 	TABLE labViewStage.appConst_element
				(
					ID          int             NOT NULL
				  , HeaderID    int             NOT NULL
				  , Name        nvarchar(100)
				  , Type        nvarchar(50)
				  , Units       nvarchar(50)
				  , Value       nvarchar(1000)	
				  , CreatedDate datetime					DEFAULT GETDATE()
				  
				  , CONSTRAINT PK_labViewStage_appConst_element 
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]
				
				  , CONSTRAINT FK_labViewStage_appConst_element_header  
						FOREIGN KEY( HeaderID ) 
						REFERENCES labViewStage.header( ID )
				)	
	  ON	[HWTTables]
			;
GO 
  
  CREATE  	INDEX IX_labViewStage_appConst_element_name 
				ON labViewStage.appConst_element
					( HeaderID ASC, Name ASC, Type ASC, Units ASC ) 
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			;
