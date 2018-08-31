CREATE TABLE
	hwt.VectorElement
		(
			VectorID		int				NOT NULL
		  , ElementID		int				NOT NULL
		  , NodeOrder		int				NOT NULL
		  , ElementValue	nvarchar(1000)	NOT NULL

		  , CONSTRAINT PK_hwt_VectorElement
				PRIMARY KEY CLUSTERED( VectorID ASC, ElementID ASC, NodeOrder ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [HWTTables]

		  , CONSTRAINT FK_hwt_VectorElement_Element
				FOREIGN KEY( ElementID )
				REFERENCES hwt.Element( ElementID )

		  , CONSTRAINT FK_hwt_VectorElement_Vector
				FOREIGN KEY( VectorID )
				REFERENCES hwt.Vector( VectorID )
		)
		ON [HWTTables]
	;
GO

CREATE INDEX
	IX_hwt_VectorElement_VectorID
		ON		hwt.VectorElement( VectorID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
GO

CREATE INDEX
	IX_hwt_VectorElement_ElementID
		ON		hwt.VectorElement( ElementID ASC )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
