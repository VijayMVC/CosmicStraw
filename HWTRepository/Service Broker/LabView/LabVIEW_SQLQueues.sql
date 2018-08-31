CREATE QUEUE
	labViewStage.SQLSenderQueue
		WITH	STATUS		=	ON
			  , RETENTION	=	OFF
			  , ACTIVATION
					(
					    STATUS				=	ON
					  , PROCEDURE_NAME		=	labViewStage.usp_Process_SQLSender
					  , MAX_QUEUE_READERS	=	4
					  , EXECUTE AS N'dbo'
					)
			  ,	 POISON_MESSAGE_HANDLING ( STATUS = ON )
		ON	[PRIMARY]
	;
GO

CREATE QUEUE
	labViewStage.SQLMessageQueue
		WITH	STATUS		=	ON
			  , RETENTION	=	OFF
			  , ACTIVATION
					(
					    STATUS				=	ON
					  , PROCEDURE_NAME		=	labViewStage.usp_Process_SQLMessage
					  , MAX_QUEUE_READERS	=	4
					  , EXECUTE AS N'dbo'
					 )
			  ,	 POISON_MESSAGE_HANDLING ( STATUS = ON )
		ON	[PRIMARY]
	;
