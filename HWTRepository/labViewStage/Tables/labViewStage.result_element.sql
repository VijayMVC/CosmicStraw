CREATE TABLE
	labViewStage.result_element
		(
			ID				int				NOT NULL	IDENTITY
		  , VectorID		int				NOT NULL
		  , Name			nvarchar(250)
		  , Type			nvarchar(50)
		  , Units			nvarchar(250)
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

CREATE INDEX
	IX_labViewStage_result_element_ResultKey
		ON		labViewStage.result_element( Name ASC, [Type] ASC, Units ASC )
					INCLUDE( VectorID, NodeOrder )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE INDEX
	IX_labViewStage_result_element_VectorID
		ON		labViewStage.result_element( VectorID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO
