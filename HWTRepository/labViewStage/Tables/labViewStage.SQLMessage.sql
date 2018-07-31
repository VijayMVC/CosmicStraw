CREATE	TABLE labViewStage.SQLMessage
			(
				SQLMessageID			int					NOT NULL	IDENTITY
			  , MessageProcessor		sysname				NOT NULL
			  , MessageType				sysname				NOT NULL
			  , ConversationHandle		uniqueidentifier	NOT NULL	DEFAULT 0x
			  , MessageSequenceNumber	bigint				NOT NULL	DEFAULT 0
			  , MessageBody				nvarchar(max)
			  , MessageQueued			datetime2(3)		NOT NULL
			  , ErrorCode				int					NOT NULL	DEFAULT 0
			  , MessageProcessed		datetime2(3)		NOT NULL
			  , CreatedDate				datetime2(3)		NOT NULL	DEFAULT SYSDATETIME()

			  , CONSTRAINT PK_utility_SQLMessage_Processed
					PRIMARY KEY NONCLUSTERED( SQLMessageID ASC )
					WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
			)	ON [PRIMARY]
			TEXTIMAGE_ON [PRIMARY]
		;
