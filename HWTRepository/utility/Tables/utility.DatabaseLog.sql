CREATE TABLE
	utility.DatabaseLog
		(
			DatabaseLogID	INT				NOT NULL	IDENTITY
		  , PostTime		DATETIME		NOT NULL
		  , DatabaseUser	sysname			NOT NULL
		  , [Event]			sysname			NOT NULL
		  , [Schema]		sysname
		  , [Object]		sysname
		  , [TSQL]			NVARCHAR(MAX)	NOT NULL
		  , XmlEvent		XML				NOT NULL
		  , CONSTRAINT PK_utility_DatabaseLog
				PRIMARY KEY NONCLUSTERED( DatabaseLogID ASC )
		)	ON [PRIMARY]
		TEXTIMAGE_ON [PRIMARY]
	;
