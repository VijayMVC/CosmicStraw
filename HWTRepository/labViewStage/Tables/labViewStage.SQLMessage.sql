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
			  , ErrorMessage			nvarchar(2048)
			  , MessageProcessed		datetime2(3)		NOT NULL
			  , CreatedDate				datetime2(3)		NOT NULL	DEFAULT SYSDATETIME()

			  , CONSTRAINT PK_utility_SQLMessage_Processed
					PRIMARY KEY NONCLUSTERED( SQLMessageID ASC )
					WITH( DATA_COMPRESSION = PAGE )
			)	ON [PRIMARY]
			TEXTIMAGE_ON [PRIMARY]
		;
GO

  CREATE	INDEX IX_labViewStage_SQLMessage_ConversationHandle
				ON labViewStage.SQLMessage
					( ConversationHandle ASC, MessageSequenceNumber ASC )
				INCLUDE ( ErrorCode )
	WITH	( DATA_COMPRESSION = PAGE )
	  ON	[PRIMARY]
			;
