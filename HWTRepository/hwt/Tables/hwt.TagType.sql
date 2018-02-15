CREATE TABLE
    hwt.TagType(
        TagTypeID       int             NOT NULL    IDENTITY
      , Name            nvarchar(50)    NOT NULL
      , Description     nvarchar(200)   NOT NULL
      , IsUserCreated   tinyint         NOT NULL
      , UpdatedBy       sysname         NOT NULL
      , UpdatedDate     datetime        NOT NULL
      , CONSTRAINT 
			PK_hwt_TagType PRIMARY KEY CLUSTERED( TagTypeID ASC ) WITH( DATA_COMPRESSION = PAGE )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
