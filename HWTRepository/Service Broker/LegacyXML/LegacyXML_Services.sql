  CREATE	SERVICE [//HWTRepository/LegacyXML/ShredResponseService]
	  ON	QUEUE xmlStage.[LegacyXML_ShredResponseQueue]
				([//HWTRepository/LegacyXML/ShredderContract])
			;
GO

  CREATE	SERVICE [//HWTRepository/LegacyXML/ShredRequestService]
	  ON	QUEUE xmlStage.[LegacyXML_ShredRequestQueue]
				([//HWTRepository/LegacyXML/ShredderContract])
			;
