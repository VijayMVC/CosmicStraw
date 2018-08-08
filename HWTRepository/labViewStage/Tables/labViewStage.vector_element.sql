  CREATE	TABLE labViewStage.vector_element
				(
					ID				int				NOT NULL	IDENTITY
				  , VectorID		int				NOT NULL
				  , Name			nvarchar(100)
				  , Type			nvarchar(50)
				  , Units			nvarchar(50)
				  , Value			nvarchar(1000)
				  , NodeOrder		int				NOT NULL	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_labViewStage_vector_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_labViewStage_vector_element_vector
						FOREIGN KEY( VectorID )
						REFERENCES labViewStage.vector( ID )
				)
			ON [HWTTables]
			;
GO

  CREATE	INDEX UX_labViewStage_vector_element_VectorID
				ON labViewStage.vector_element
					( ID ASC, VectorID ASC )
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			; 
			
			
