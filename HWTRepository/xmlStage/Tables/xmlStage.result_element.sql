  CREATE	TABLE xmlStage.result_element
				(
					ID				int				NOT NULL	IDENTITY
				  , VectorID		int				NOT NULL
				  , Name			nvarchar(250)
				  , Type			nvarchar(50)
				  , Units			nvarchar(250)
				  , Value			nvarchar(max)
				  , NodeOrder		int				NOT NULL	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_xmlStage_result_element
						PRIMARY KEY CLUSTERED( ID )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_xmlStage_result_element_vector
						FOREIGN KEY( VectorID )
						REFERENCES xmlStage.vector( ID )
				)
			ON	[HWTTables]
			TEXTIMAGE_ON [HWTTables]
			;
GO

  CREATE	INDEX IX_xmlStage_result_element_VectorID
				ON xmlStage.result_element
					( VectorID ASC )
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON	[HWTIndexes]
			;
GO

  CREATE 	INDEX IX_xmlStage_result_element_Name 
				ON xmlStage.result_element
					( Name ASC, [Type] ASC, Units ASC ) 
	WITH	( DATA_COMPRESSION = PAGE ) 
	  ON 	[HWTIndexes]
			; 