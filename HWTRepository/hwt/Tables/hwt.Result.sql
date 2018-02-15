CREATE TABLE
    hwt.Result(
        ResultID    int             NOT NULL    IDENTITY
      , Name        nvarchar(50)    NOT NULL
      , DataType    nvarchar(50)    NOT NULL
      , Units       nvarchar(50)    NOT NULL
      , HWTChecksum int             NOT NULL
      , UpdatedBy   sysname         NOT NULL
      , UpdatedDate datetime        NOT NULL
      , CONSTRAINT 
			PK_hwt_Result PRIMARY KEY CLUSTERED( ResultID ASC ) WITH( DATA_COMPRESSION = PAGE )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
