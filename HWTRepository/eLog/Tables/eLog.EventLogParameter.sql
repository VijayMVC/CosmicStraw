CREATE 	TABLE eLog.EventLogParameter
/*
	derived from:	Error and Transaction Handling in SQL Server, Erland Sommarskog, SQL Server MVP 
					http://www.sommarskog.se/error_handling/Part1.html ( and following links )

	Revisions
	
	2018-04-27		carsoc3		Initial production launch					
	2018-08-31		carsoc3		Expand ParamValue from 400 to 4000
*/
			(
				EventLogID	bigint			NOT NULL
			  , ParamNum	tinyint			NOT NULL
			  , ParamValue	nvarchar(4000)	NOT NULL
			  
			  , CONSTRAINT 	PK_eLog_EventLogParameter 
					PRIMARY KEY CLUSTERED( EventLogID ASC, ParamNum ASC )
					
			  , CONSTRAINT FK_eLog_EventLogParameter 
					FOREIGN KEY( EventLogID ) 
					REFERENCES 	eLog.EventLog( EventLogID )
			) 
		; 
