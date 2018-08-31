CREATE TABLE
	hwt.VectorRequirement
		(
			VectorID	int				NOT NULL
		  , TagID		int				NOT NULL
		  , NodeOrder	int				NOT NULL

		  , CONSTRAINT	PK_hwt_VectorRequirement
				PRIMARY KEY CLUSTERED( VectorID, TagID, NodeOrder ASC )
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
GO

CREATE INDEX
	IX_hwt_VectorRequirement_VectorID
		ON		hwt.VectorRequirement( VectorID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE	INDEX
	IX_hwt_VectorRequirement_TagID
		ON		hwt.VectorRequirement( TagID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
