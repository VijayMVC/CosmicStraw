  CREATE	TABLE labViewStage.error_element
				(
					ID				int				NOT NULL	IDENTITY
				  , VectorID		int				NOT NULL
				  , ErrorCode		int				NOT NULL
				  , ErrorText		nvarchar(max)	NOT NULL
				  , NodeOrder		int				NOT NULL 	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()
				  , PublishDate		datetime2(3)

				  , CONSTRAINT PK_labViewStage_error_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT FK_labViewStage_error_element_vector
						FOREIGN KEY( VectorID )
						REFERENCES labViewStage.vector( ID )
				)
				ON	[HWTTables]
				TEXTIMAGE_ON [HWTTables]
			;