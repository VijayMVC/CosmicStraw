  CREATE	QUEUE xmlStage.LegacyXML_ShredRequestQueue
	WITH	ACTIVATION
				(
					STATUS				=	ON
				  , PROCEDURE_NAME		=	xmlStage.usp_LegacyXML_ShredRequest
				  , MAX_QUEUE_READERS	=	1
				  , EXECUTE AS N'dbo'
				)
	  ON	[PRIMARY]
			;
GO

  CREATE	QUEUE xmlStage.LegacyXML_ShredResponseQueue
	WITH	ACTIVATION
				(
					STATUS				=	ON
				  , PROCEDURE_NAME		=	xmlStage.usp_LegacyXML_ShredResponse
				  , MAX_QUEUE_READERS	=	1
				  , EXECUTE AS N'dbo'
				)
	  ON	[PRIMARY]
			;
