CREATE TABLE
    archive.[Option](
        OptionID            int             NOT NULL
      , Name                nvarchar(100)   NOT NULL
      , ShortName           nvarchar(50)    NOT NULL
      , DataType            nvarchar(50)    NOT NULL
      , Units               nvarchar(50)    NOT NULL
      , ValueText           nvarchar(50)
      , ValueInt            int
      , ValueNum            decimal(18, 14)
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_Option_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_Option PRIMARY KEY CLUSTERED( OptionID, VersionNumber )
);
