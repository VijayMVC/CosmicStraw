CREATE 	TABLE utility.ExcelAddIn 
			(
				ExcelAddInID	int				NOT NULL 	IDENTITY
			  , CompletePath 	nvarchar(400) 	NOT NULL
			  , DisplayName  	nvarchar(50)  	NOT NULL
			  , ExcelSubName 	sysname	      	NOT NULL
			  , DisplayOrder 	int            	NOT NULL
			  
			  , CONSTRAINT PK_utility_ExcelAddIn 
					PRIMARY KEY CLUSTERED( ExcelAddInID ASC ) 
					WITH( DATA_COMPRESSION = PAGE ) 
					ON [HWTTables]
			) 	
		ON [HWTTables]
;
