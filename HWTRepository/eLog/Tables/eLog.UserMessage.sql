CREATE TABLE 	eLog.UserMessage
/*
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP 
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )
*/
	(
		MessageID	varchar(36)		NOT NULL
	  , LCID		smallint		NOT NULL
	  , MessageText	nvarchar(1960)	NOT NULL
	  , UpdatedBy	sysname			NOT NULL
	  , UpdatedDate	datetime		NOT NULL	DEFAULT GETDATE()
	  
	  , CONSTRAINT 	PK_eLog_UserMessage 		
			PRIMARY KEY CLUSTERED( MessageID ASC, LCID ASC )
	) ;
