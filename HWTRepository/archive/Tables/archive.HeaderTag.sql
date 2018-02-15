CREATE TABLE
    archive.HeaderTag(
        HeaderID            int             NOT NULL
      , TagID               int             NOT NULL
      , Notes               nvarchar(200)   NOT NULL
      , UpdatedBy           sysname         NOT NULL
      , UpdatedDate         datetime        NOT NULL
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_HeaderTag_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_HeaderTag         PRIMARY KEY CLUSTERED( HeaderID, TagID )
);
