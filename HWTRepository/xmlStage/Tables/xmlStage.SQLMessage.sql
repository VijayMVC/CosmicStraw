CREATE TABLE	xmlStage.SQLMessage
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

					  , CONSTRAINT PK_xmlStage_SQLMessage
							PRIMARY KEY NONCLUSTERED( SQLMessageID ASC )
							WITH( DATA_COMPRESSION = PAGE )
					)
				;
GO

CREATE INDEX	IX_xmlStage_SQLMessage_ConversationHandle
					ON xmlStage.SQLMessage
						( ConversationHandle ASC, MessageSequenceNumber ASC )
				INCLUDE ( ErrorCode )
		WITH	( DATA_COMPRESSION = PAGE )
				;
