  CREATE	TABLE hwt.HeaderTag
				(
					HeaderID	int				NOT NULL
				  , TagID		int				NOT NULL
				  , Notes		nvarchar(200)	NOT NULL
				  , UpdatedBy	sysname			NOT NULL
				  , UpdatedDate datetime		NOT NULL

				  , CONSTRAINT	PK_hwt_HeaderTag
						PRIMARY KEY CLUSTERED( HeaderID, TagID )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT	FK_hwt_HeaderTag_Header
						FOREIGN KEY( HeaderID )
						REFERENCES hwt.Header( HeaderID )

				  , CONSTRAINT	FK_hwt_HeaderTag_Tag
						FOREIGN KEY( TagID )
						REFERENCES hwt.Tag( TagID )
				)
			ON [HWTTables]
			;
