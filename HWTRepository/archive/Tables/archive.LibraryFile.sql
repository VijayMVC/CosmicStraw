CREATE TABLE
    archive.LibraryFile(
        LibraryFileID       int             NOT NULL
      , FileName            nvarchar(400)   NOT NULL
      , FileRev             nvarchar(50)    NOT NULL
      , Status              nvarchar(50)    NOT NULL
      , HashCode            nvarchar(100)
      , UpdatedDate         datetime        NOT NULL
      , UpdatedBy           sysname         NOT NULL
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_LibraryFile_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_LibraryFile PRIMARY KEY CLUSTERED (LibraryFileID)
);
