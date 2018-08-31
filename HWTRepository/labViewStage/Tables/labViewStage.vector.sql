CREATE TABLE
	labViewStage.vector
		(
			ID				int				NOT NULL	IDENTITY
		  , HeaderID		int				NOT NULL
		  , VectorNum		int				NOT NULL
		  , Loop			int				NOT NULL	DEFAULT 0
		  , ReqID			nvarchar(1000)
		  , StartTime		nvarchar(50)
		  , EndTime			nvarchar(50)
		  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()

		  , CONSTRAINT PK_labViewStage_vector
				PRIMARY KEY NONCLUSTERED( ID )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_labViewStage_vector_header
				FOREIGN KEY( HeaderID )
				REFERENCES labViewStage.header( ID )
		)
		ON	[HWTTables]
	;
GO

CREATE UNIQUE CLUSTERED INDEX
	UX_labViewStage_vector_Key
		ON		labViewStage.vector
					(
						HeaderID ASC, VectorNum ASC, Loop ASC, StartTime ASC
					)
		WITH	( DATA_COMPRESSION = PAGE )
		ON	[HWTTables]
	;
GO

CREATE UNIQUE INDEX
	UX_labViewStage_vector_HeaderID
		ON		labViewStage.vector( HeaderID ASC, ID ASC )
					INCLUDE( ReqID, StartTime, EndTime )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
