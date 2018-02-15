CREATE TABLE
    hwt.VectorResult(
        VectorID    int             NOT NULL
      , ResultID    int             NOT NULL
      , ResultN     int				NOT NULL
      , ResultValue	nvarchar(50)	NOT NULL
      , CONSTRAINT
            PK_hwt_VectorResult PRIMARY KEY CLUSTERED( VectorID ASC, ResultID ASC, ResultN ASC ) WITH( DATA_COMPRESSION = PAGE )
      , CONSTRAINT
            FK_hwt_VectorResult_Result FOREIGN KEY( ResultID ) REFERENCES hwt.Result( ResultID )
      , CONSTRAINT
            FK_hwt_VectorResult_Vector FOREIGN KEY( VectorID ) REFERENCES hwt.Vector( VectorID )
	)
	WITH( DATA_COMPRESSION = PAGE )
;
GO

CREATE NONCLUSTERED INDEX 
	IX_hwt_VectorResult_VectorIDResultID
		ON hwt.VectorResult( VectorID ASC, ResultID ASC ) 
		WITH ( DATA_COMPRESSION = PAGE ) 
;
