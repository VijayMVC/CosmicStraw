CREATE TABLE
	eLog.ServiceBrokerMessage
		(
			MessageID				int					NOT NULL	IDENTITY
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

		  , CONSTRAINT PK_eLog_ServiceBrokerMessage
				PRIMARY KEY CLUSTERED( MessageID ASC )
				WITH( DATA_COMPRESSION = PAGE )
				ON [PRIMARY]

		)
		ON [PRIMARY]
		TEXTIMAGE_ON [PRIMARY]
	;
GO

CREATE INDEX
	IX_eLog_ServiceBrokerMessage_ConversationHandle
		ON		eLog.ServiceBrokerMessage
					(
						MessageProcessor ASC, ConversationHandle ASC, MessageSequenceNumber ASC
					)
					INCLUDE ( ErrorCode )
		WITH	( DATA_COMPRESSION = PAGE )
		ON		[HWTIndexes]
	;
