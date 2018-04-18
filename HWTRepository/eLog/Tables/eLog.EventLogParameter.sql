CREATE TABLE 	eLog.EventLogParameter
/*
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP 
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )

*/
	(
		EventLogID	bigint			NOT NULL
	  , ParamNum	tinyint			NOT NULL
	  , ParamValue	nvarchar(400)	NOT NULL
	  
	  , CONSTRAINT 	PK_eLog_EventLogParameter 
			PRIMARY KEY CLUSTERED( EventLogID ASC, ParamNum ASC )
			
	  , CONSTRAINT FK_eLog_EventLogParameter 
			FOREIGN KEY( EventLogID ) 
			REFERENCES 	eLog.EventLog( EventLogID )
	) ; 