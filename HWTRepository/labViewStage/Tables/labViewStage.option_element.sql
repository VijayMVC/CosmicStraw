﻿  CREATE	TABLE labViewStage.option_element
				(
					ID				int				NOT NULL	IDENTITY
				  , HeaderID		int				NOT NULL
				  , Name			nvarchar(100)
				  , Type			nvarchar(50)
				  , Units			nvarchar(50)
				  , Value			nvarchar(1000)
				  , NodeOrder		int				NOT NULL 	DEFAULT 0
				  , CreatedDate		datetime2(3)	NOT NULL	DEFAULT SYSDATETIME()
				  , PublishDate		datetime2(3)

				  , CONSTRAINT	PK_labViewStage_option_element
						PRIMARY KEY CLUSTERED( ID ASC )
						WITH( DATA_COMPRESSION = PAGE )
						ON [HWTTables]

				  , CONSTRAINT	FK_labViewStage_option_element_header
						FOREIGN KEY( HeaderID )
						REFERENCES labViewStage.header( ID )
				)
			ON [HWTTables]
			;
GO

  CREATE	INDEX IX_labViewStage_option_element_name
				ON	labViewStage.option_element
					( HeaderID ASC, Name ASC, Type ASC, Units ASC )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[HWTIndexes]
			;


