CREATE TABLE 	labViewStage.vector_element
				(
					ID          int             NOT NULL
				  , VectorID    int             NOT NULL
				  , Name        nvarchar(100)
				  , Type        nvarchar(50)
				  , Units       nvarchar(50)
				  , Value       nvarchar(1000)
				  , CreatedDate	datetime					DEFAULT GETDATE()
				  
				  , CONSTRAINT PK_labViewStage_vector_element 
						PRIMARY KEY CLUSTERED( ID ASC ) 
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]
				
				  , CONSTRAINT FK_labViewStage_vector_element_vector 
						FOREIGN KEY( VectorID ) 
						REFERENCES labViewStage.vector( ID )
				) 
				;
