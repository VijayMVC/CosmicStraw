﻿CREATE TABLE	hwt.HeaderAppConst
				(
					HeaderID		int             NOT NULL
				  , AppConstID		int             NOT NULL
				  , AppConstN		int				NOT NULL
				  , AppConstValue	nvarchar(1000)  NOT NULL
				  , UpdatedBy		sysname         NOT NULL
				  , UpdatedDate		datetime        NOT NULL
				  
				  , CONSTRAINT	PK_hwt_HeaderAppConst 
						PRIMARY KEY CLUSTERED( HeaderID ASC, AppConstID ASC, AppConstN ASC ) 
						WITH( DATA_COMPRESSION = PAGE ) 
						ON [HWTTables]

				  , CONSTRAINT 	FK_hwt_HeaderAppConst_AppConst 
						FOREIGN KEY( AppConstID ) 
						REFERENCES hwt.AppConst( AppConstID )
						
				  , CONSTRAINT FK_hwt_HeaderAppConst_Header 
						FOREIGN KEY( HeaderID ) 
						REFERENCES hwt.Header( HeaderID )
				)	ON [HWTTables]
				;
