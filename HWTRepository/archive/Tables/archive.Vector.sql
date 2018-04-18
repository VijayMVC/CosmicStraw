CREATE TABLE
    archive.Vector(
        VectorID            int             NOT NULL
      , HeaderID            int             NOT NULL
      , VectorNumber        int             NOT NULL
      , LoopNumber          int             NOT NULL
      , StartDate           datetime
      , EndDate             datetime
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_Vector_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_Vector        PRIMARY KEY CLUSTERED( VectorID, VersionNumber )
);
