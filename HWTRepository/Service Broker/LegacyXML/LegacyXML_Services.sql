CREATE SERVICE 
	[//HWTRepository/ShredLegacyXML/ResponseService]
		ON QUEUE xmlStage.ShredLegacyXML_ResponseQueue
			( [//HWTRepository/ShredLegacyXML/Contract] )
	;
GO

CREATE SERVICE 
	[//HWTRepository/ShredLegacyXML/RequestService]
		ON QUEUE xmlStage.ShredLegacyXML_RequestQueue
			( [//HWTRepository/ShredLegacyXML/Contract] )
	;
