CREATE TABLE
    archive.Header(
        HeaderID                int             NOT NULL
      , ResultFileName          nvarchar(1000)  NOT NULL
      , StartTime               datetime        NOT NULL
      , FinishTime              datetime
      , Duration                varchar(30)     NOT NULL
      , TestStationName         nvarchar(100)   NOT NULL
      , TestName                nvarchar(250)   NOT NULL
      , TestConfigFile          nvarchar(400)   NOT NULL
      , TestCodePathName        nvarchar(400)   NOT NULL
      , TestCodeRevision        nvarchar(100)   NOT NULL
      , HWTSysCodeRevision      nvarchar(100)   NOT NULL
      , KdrivePath              nvarchar(400)   NOT NULL
      , Comments                nvarchar(max)   NOT NULL
      , ExternalFileInfo        nvarchar(max)   NOT NULL
      , VersionNumber           int             NOT NULL
      , VersionTimestamp        datetime2(7)    NOT NULL    CONSTRAINT DF_archive_header_VersionTimestamp DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_Header PRIMARY KEY CLUSTERED( HeaderID, VersionNumber )
);
