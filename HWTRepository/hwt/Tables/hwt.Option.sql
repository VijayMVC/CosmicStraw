CREATE TABLE
    hwt.[Option](
        OptionID    int             NOT NULL    IDENTITY
      , Name        nvarchar(100)   NOT NULL
      , DataType    nvarchar(50)    NOT NULL
      , Units       nvarchar(50)    NOT NULL
      , HWTChecksum int             NOT NULL
      , UpdatedBy   sysname         NOT NULL
      , UpdatedDate datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_Option PRIMARY KEY CLUSTERED( OptionID ASC ) WITH( DATA_COMPRESSION = PAGE )
	  , CONSTRAINT 
			UK_hwt_Option UNIQUE( Name )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
