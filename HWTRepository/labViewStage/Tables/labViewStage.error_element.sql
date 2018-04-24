CREATE TABLE	labViewStage.error_element
				(
					ID          int             NOT NULL
				  , VectorID    int             NOT NULL
				  , ErrorCode   int             NOT NULL
				  , ErrorText   nvarchar(max)   NOT NULL
				  , CreatedDate datetime					DEFAULT GETDATE()				  
      
				  , CONSTRAINT PK_labViewStage_error_element 
						PRIMARY KEY CLUSTERED( ID ASC ) 
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]
			
				  , CONSTRAINT FK_labViewStage_error_element_vector 
						FOREIGN KEY( VectorID ) 
						REFERENCES labViewStage.vector( ID )
				)	ON	[HWTTables]
				TEXTIMAGE_ON [HWTTables]
				;