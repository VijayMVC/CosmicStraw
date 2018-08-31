CREATE QUEUE
	xmlStage.CompareXML_RequestQueue
		WITH	STATUS		=	ON
		      , RETENTION	=	OFF
			  , ACTIVATION
					(
						STATUS				=	ON
					  , PROCEDURE_NAME		=	xmlStage.usp_CompareXML_Request
					  , MAX_QUEUE_READERS	=	4
					  , EXECUTE AS N'dbo'
					)
			  ,	 POISON_MESSAGE_HANDLING ( STATUS = ON )
		ON	[PRIMARY]
	;
GO

CREATE QUEUE
	xmlStage.CompareXML_ResponseQueue
		WITH	STATUS		=	ON
			  , RETENTION	=	OFF
			  , ACTIVATION
					(
						STATUS				=	ON
					  , PROCEDURE_NAME		=	xmlStage.usp_CompareXML_Response
					  , MAX_QUEUE_READERS	=	4
					  , EXECUTE AS N'dbo'
					)
			  ,	 POISON_MESSAGE_HANDLING ( STATUS = ON )
		ON	[PRIMARY]
	;
