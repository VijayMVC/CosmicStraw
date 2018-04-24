CREATE TABLE	hwt.VectorElement
				(
					VectorID		int             NOT NULL
				  , ElementID		int             NOT NULL
				  , ElementN		int				NOT NULL
				  , ElementValue	nvarchar(1000)	NOT NULL
				  , UpdatedBy		sysname         NOT NULL
				  , UpdatedDate		datetime        NOT NULL
				
				  , CONSTRAINT PK_hwt_VectorElement 
						PRIMARY KEY CLUSTERED( VectorID ASC, ElementID ASC, ElementN ASC ) 
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]

				  , CONSTRAINT FK_hwt_VectorElement_Element 
						FOREIGN KEY( ElementID ) 
						REFERENCES hwt.Element( ElementID )
				  
				  , CONSTRAINT FK_hwt_VectorElement_Vector 
						FOREIGN KEY( VectorID ) 
						REFERENCES hwt.Vector( VectorID )
				)	ON [HWTTables]
				;
