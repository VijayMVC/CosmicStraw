CREATE TABLE
	labViewStage.error_element
		(
			ID				int				NOT NULL	IDENTITY
		  , VectorID		int				NOT NULL
		  , ErrorType		int				NOT NULL	DEFAULT 1
				--	ErrorType 1:  test error
				--	ErrorType 2:  data error
				--	ErrorType 3:  input parameter error

		  , ErrorCode		int				NOT NULL
		  , ErrorText		nvarchar(max)	NOT NULL
		  , NodeOrder		int				NOT NULL	DEFAULT 0
		  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

		  , CONSTRAINT PK_labViewStage_error_element
				PRIMARY KEY CLUSTERED( ID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_labViewStage_error_element_vector
				FOREIGN KEY( VectorID )
				REFERENCES labViewStage.vector( ID )

		  , CONSTRAINT	CK_labViewStage_VectorError_ErrorType
				CHECK( ErrorType IN ( 1, 2, 3 ) )
		)
		ON	[HWTTables]
		TEXTIMAGE_ON [HWTTables]
	;
GO

CREATE INDEX
	IX_labViewStage_error_element_VectorID
		ON		labViewStage.error_element( VectorID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
