CREATE TABLE
    hwt.LibraryFile(
        LibraryFileID   int             NOT NULL     IDENTITY
      , FileName        nvarchar(400)   NOT NULL
      , FileRev         nvarchar(50)    NOT NULL
      , Status          nvarchar(50)    NOT NULL
      , HashCode        nvarchar(100)
      , HWTChecksum     int             NOT NULL
      , UpdatedBy       sysname         NOT NULL
      , UpdatedDate     datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_LibraryFile PRIMARY KEY CLUSTERED( LibraryFileID ASC ) WITH( DATA_COMPRESSION = PAGE )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
