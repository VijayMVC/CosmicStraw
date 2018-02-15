CREATE TABLE
    archive.HeaderOption(
        HeaderID            int             NOT NULL
      , OptionID            int             NOT NULL
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_HeaderOption_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_HeaderOption  PRIMARY KEY CLUSTERED( HeaderID, OptionID, VersionNumber )
);
