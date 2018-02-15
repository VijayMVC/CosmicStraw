CREATE TABLE 
	utility.ErrorLog(
        ErrorLogID		int             NOT NULL	IDENTITY
      , ErrorTime		datetime        NOT NULL
      , UserName		sysname			NOT NULL
      , ErrorNumber		int             NOT NULL
      , ErrorSeverity	int             
      , ErrorState		int             
      , ErrorProcedure	sysname
      , ErrorLine		int             
      , ErrorMessage	nvarchar (4000) NOT NULL
      , CONSTRAINT PK_utility_ErrorLog 
			PRIMARY KEY CLUSTERED( ErrorLogID ASC ) WITH( DATA_COMPRESSION = PAGE )
);

