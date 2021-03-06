﻿CREATE TABLE
    xmlStage.libraryInfo_file(
        ID          int             NOT NULL    IDENTITY
      , HeaderID    int             NOT NULL
      , FileName    nvarchar(400)
      , FileRev     nvarchar(50)
      , Status      nvarchar(50)
      , HashCode    nvarchar(100)
      , CONSTRAINT 
			PK_xmlStge_libraryInfo_file PRIMARY KEY CLUSTERED( ID ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT 
			FK_xmlStge_libraryInfo_file_header FOREIGN KEY( HeaderID ) REFERENCES xmlStage.header( ID )
    )
;
