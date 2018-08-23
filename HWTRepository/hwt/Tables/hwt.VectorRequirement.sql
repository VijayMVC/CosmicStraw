  CREATE	TABLE hwt.VectorRequirement
				(
					VectorID	int				NOT NULL
				  , TagID		int				NOT NULL
				  , NodeOrder	int				NOT NULL
				  , UpdatedBy	sysname			NOT NULL
				  , UpdatedDate datetime2(3)	NOT NULL

				  , CONSTRAINT	PK_hwt_VectorRequirement
						PRIMARY KEY CLUSTERED( VectorID, TagID )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT	FK_hwt_VectorRequirement_Vector
						FOREIGN KEY( VectorID )
						REFERENCES hwt.Vector( VectorID )

				  , CONSTRAINT	FK_hwt_VectorRequirement_Tag
						FOREIGN KEY( TagID )
						REFERENCES hwt.Tag( TagID )
				)
			ON [HWTTables]
			;
