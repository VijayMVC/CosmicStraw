CREATE TABLE
    hwt.AppConst(
        AppConstID  int             NOT NULL    IDENTITY
      , Name        nvarchar(100)   NOT NULL
      , DataType    nvarchar(50)    NOT NULL
      , Units       nvarchar(50)    NOT NULL
      , HWTChecksum int             NOT NULL
      , UpdatedBy   sysname         NOT NULL
      , UpdatedDate datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_AppConst PRIMARY KEY CLUSTERED( AppConstID ASC ) WITH( DATA_COMPRESSION = PAGE )
	  , CONSTRAINT
			UK_hwt_AppConst_Name UNIQUE( Name )			
	)
	WITH( DATA_COMPRESSION = PAGE )
;
