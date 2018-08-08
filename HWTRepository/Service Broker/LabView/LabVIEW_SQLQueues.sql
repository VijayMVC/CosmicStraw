  CREATE	QUEUE labViewStage.SQLSenderQueue
 	WITH	ACTIVATION
				(
				    PROCEDURE_NAME		=	labViewStage.usp_Process_SQLSender
				  , MAX_QUEUE_READERS	=	4
				  , EXECUTE AS N'dbo'
				  , STATUS				=	OFF
				)
			  ,  POISON_MESSAGE_HANDLING (STATUS = OFF) 

	  ON	[PRIMARY]
			;
GO

  CREATE	QUEUE labViewStage.SQLMessageQueue
	WITH	ACTIVATION
 				(
				    PROCEDURE_NAME		=	labViewStage.usp_Process_SQLMessage
				  , MAX_QUEUE_READERS	=	4
				  , EXECUTE AS N'dbo'
				  , STATUS				=	OFF
				 ) 
	  ON	[PRIMARY]
			;
