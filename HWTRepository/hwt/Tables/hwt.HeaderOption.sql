CREATE TABLE
    hwt.HeaderOption(
        HeaderID    int             NOT NULL
      , OptionID    int             NOT NULL
      , OptionValue	nvarchar(1000)	NOT NULL
      , UpdatedBy   sysname         NOT NULL
      , UpdatedDate datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_HeaderOption PRIMARY KEY CLUSTERED( HeaderID ASC, OptionID ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT
            FK_hwt_HeaderOption_Header FOREIGN KEY( HeaderID ) REFERENCES hwt.Header( HeaderID )
      , CONSTRAINT
            FK_hwt_HeaderOption_Option FOREIGN KEY( OptionID ) REFERENCES hwt.[Option]( OptionID )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
