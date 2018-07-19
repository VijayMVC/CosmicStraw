CREATE TABLE	labViewStage.SQLMessage
				(
					SQLMessageID 		int     		NOT NULL	IDENTITY
				  , MessageProcessor    sysname			NOT NULL
				  , MessageBody			nvarchar(max)	NOT NULL
				  , MessageQueued		datetime2(7)	NOT NULL
				  , ErrorCode			int				NOT NULL	DEFAULT 0 
				  , CreatedDate			datetime2(7)	NOT NULL	DEFAULT SYSDATETIME()

				  , CONSTRAINT PK_utility_SQLMessage_Processed
						PRIMARY KEY NONCLUSTERED( SQLMessageID ASC )
						WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
				) 	ON [PRIMARY]
				TEXTIMAGE_ON [PRIMARY]
				;


