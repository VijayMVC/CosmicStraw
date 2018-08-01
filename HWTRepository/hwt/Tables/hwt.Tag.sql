  CREATE	TABLE hwt.Tag
				(
					TagID		int				NOT NULL	IDENTITY
				  , TagTypeID	int				NOT NULL
				  , Name		nvarchar(50)	NOT NULL
				  , Description nvarchar(200)	NOT NULL
				  , IsDeleted	tinyint			NOT NULL
				  , UpdatedBy	sysname			NOT NULL
				  , UpdatedDate datetime		NOT NULL

				  , CONSTRAINT	PK_hwt_Tag
						PRIMARY KEY CLUSTERED( TagID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]


				  , CONSTRAINT	FK_hwt_Tag_TagType
						FOREIGN KEY( TagTypeID )
						REFERENCES hwt.TagType( TagTypeID )

					, CONSTRAINT
						UK_hwt_Tag_Name UNIQUE( TagTypeID, Name )
				)
			ON [HWTTables]
			;
GO

  CREATE	UNIQUE INDEX UX_hwt_Tag_Name
				ON hwt.Tag
					( TagTypeID ASC, Name ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;
