CREATE TABLE
	hwt.AppConst
		(
			AppConstID	int				NOT NULL	IDENTITY
		  , Name		nvarchar(250)	NOT NULL
		  , DataType	nvarchar(50)	NOT NULL
		  , Units		nvarchar(250)	NOT NULL
		  , CreatedBy	sysname			NOT NULL
		  , CreatedDate datetime2(3)	NOT NULL

		  , CONSTRAINT	PK_hwt_AppConst
				PRIMARY KEY CLUSTERED( AppConstID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]
		)
		ON [HWTTables]
	;
GO

CREATE UNIQUE INDEX
	UX_hwt_AppConst_Key
		ON		hwt.AppConst( Name ASC, DataType ASC, Units ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
