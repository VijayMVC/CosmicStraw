CREATE TABLE
    archive.Equipment(
        EquipmentID         int             NOT NULL
      , Description         nvarchar(100)   NOT NULL
      , Asset               nvarchar(50)    NOT NULL
      , CalibrationDueDate  datetime        NOT NULL
      , CostCenter          nvarchar(50)    NOT NULL
      , UpdatedBy           sysname         NOT NULL
      , UpdatedDate         datetime        NOT NULL
      , VersionNumber       int             NOT NULL
      , VersionTimestamp    datetime2(7)    NOT NULL    CONSTRAINT DF_archive_Equipment_VersionTimestamp    DEFAULT SYSDATETIME()
      , CONSTRAINT PK_archive_Equipment PRIMARY KEY CLUSTERED( EquipmentID, VersionNumber )
);
