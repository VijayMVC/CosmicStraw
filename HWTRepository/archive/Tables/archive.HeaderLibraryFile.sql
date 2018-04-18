CREATE TABLE
    archive.HeaderLibraryFile(
        HeaderID            int             NOT NULL
      , LibraryFileID       int             NOT NULL
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL        CONSTRAINT DF_archive_HeaderLibraryFile_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_HeaderLibraryFile             PRIMARY KEY CLUSTERED( HeaderID, LibraryFileID )
);
