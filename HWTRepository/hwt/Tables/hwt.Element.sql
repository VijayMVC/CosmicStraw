﻿CREATE TABLE
    hwt.Element(
        ElementID   int             NOT NULL    IDENTITY
      , Name        nvarchar(100)   NOT NULL
      , DataType    nvarchar(50)    NOT NULL
      , Units       nvarchar(1000)  NOT NULL
      , HWTChecksum int             NOT NULL
      , UpdatedBy   sysname         NOT NULL
      , UpdatedDate datetime        NOT NULL
      , CONSTRAINT
            PK_hwt_Element PRIMARY KEY CLUSTERED( ElementID ASC ) WITH( DATA_COMPRESSION = PAGE )
	  , CONSTRAINT
			UK_hwt_Element UNIQUE( Name ASC, DataType ASC, Units ASC )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
