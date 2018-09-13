  CREATE	SERVICE [//HWTRepository/CompareXML/ResponseService]
	  ON	QUEUE xmlStage.[CompareXML_ResponseQueue]
				([//HWTRepository/CompareXML/CompareXMLContract])
			;
GO

  CREATE	SERVICE [//HWTRepository/CompareXML/RequestService]
	  ON	QUEUE xmlStage.[CompareXML_RequestQueue]
				([//HWTRepository/CompareXML/CompareXMLContract])
			;
