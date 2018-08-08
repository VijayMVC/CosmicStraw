  CREATE	TABLE labViewStage.result_element
				(
					ID				int				NOT NULL	IDENTITY
				  , VectorID		int				NOT NULL
				  , Name			nvarchar(250)
				  , Type			nvarchar(50)
				  , Units			nvarchar(50)
				  , Value			nvarchar(max)
				  , NodeOrder		int				NOT NULL	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_labViewStage_result_element
						PRIMARY KEY CLUSTERED( ID )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_labViewStage_result_element_vector
						FOREIGN KEY( VectorID )
						REFERENCES labViewStage.vector( ID )
				)
			ON	[HWTTables]
			TEXTIMAGE_ON [HWTTables]
			;
GO

  CREATE	UNIQUE INDEX UX_labViewStage_result_element_VectorID
				ON labViewStage.result_element
					( ID ASC, VectorID ASC )
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			; 