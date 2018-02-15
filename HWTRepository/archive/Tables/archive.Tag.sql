CREATE TABLE 
	archive.Tag(
		TagID       		int				NOT NULL
	  , TagTypeID   		int            	NOT NULL
	  , Name        		nvarchar(50)  	NOT NULL 	
	  , Description			nvarchar(200) 	NOT NULL 	
	  , IsPermanent 		tinyint        	NOT NULL 	
	  , IsDeleted   		tinyint        	NOT NULL 	
	  , UpdatedDate 		datetime       	NOT NULL 	
	  , UpdatedBy   		sysname      	NOT NULL 
	  , VersionNumber		int				NOT NULL	
	  , VersionTimestamp	datetime2(7)	NOT NULL	CONSTRAINT DF_archive_Tag_VersionTimestamp DEFAULT SYSDATETIME()
	  , CONSTRAINT PK_archive_Tag	PRIMARY KEY CLUSTERED( TagID, VersionNumber )  
);
