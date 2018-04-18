CREATE TABLE
    archive.TagType(
        TagTypeID           int             NOT NULL
      , Name                nvarchar(50)    NOT NULL
      , Description         nvarchar(200)   NOT NULL
      , IsUserCreated       tinyint         NOT NULL
      , UpdatedDate         datetime        NOT NULL
      , UpdatedBy           sysname         NOT NULL
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_TagType_VersionTimestamp  DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_TagType       PRIMARY KEY CLUSTERED( TagTypeID )
);
