CREATE TABLE	xmlStage.ShreddedFile
	(
        FileID			uniqueidentifier	NOT NULL  
	  , HeaderID		int					
	  , ShredRequested	datetime2(3)								
	  , RequestedBy		varchar(128)							
	  , ShredCompleted	datetime2(3)							
	  , CompletedBy		varchar(128)
      , CONSTRAINT PK_xmlStage_ShreddedFiles 
			PRIMARY KEY CLUSTERED( FileID ASC ) 
			WITH( DATA_COMPRESSION = PAGE )
    )
;
GO
