CREATE SERVICE
	[//HWTRepository/CompareXML/ResponseService]
		ON	QUEUE xmlStage.CompareXML_ResponseQueue
			( [//HWTRepository/CompareXML/Contract] )
	;
GO

CREATE SERVICE
	[//HWTRepository/CompareXML/RequestService]
		ON	QUEUE xmlStage.[CompareXML_RequestQueue]
			( [//HWTRepository/CompareXML/Contract] )
	;
