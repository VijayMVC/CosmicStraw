CREATE TABLE	labViewStage.result_element
				(
					ID          int             NOT NULL
				  , VectorID    int             NOT NULL
				  , Name        nvarchar(250)
				  , Type        nvarchar(50)
				  , Units       nvarchar(50)
				  , Value       nvarchar(max)
  				  , CreatedDate datetime					DEFAULT GETDATE()

				  , CONSTRAINT PK_labViewStage_result_element 
						PRIMARY KEY CLUSTERED( ID ) 
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]
				
				  , CONSTRAINT FK_labViewStage_result_element_vector 
						FOREIGN KEY( VectorID ) 
						REFERENCES labViewStage.vector( ID )
				)	ON	[HWTTables]
				TEXTIMAGE_ON [HWTTables]
				;
GO 
  
CREATE INDEX 	IX_labViewStage_result_element_vector 
		  ON 	labViewStage.result_element
					( VectorID ASC, Name ASC, Type ASC, Units ASC ) 
		WITH	( DATA_COMPRESSION = PAGE ) 
		  ON	[HWTIndexes]
				;