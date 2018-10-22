CREATE	SERVICE [//HWTRepository/LegacyXML/ShredResponseService]
		ON QUEUE xmlStage.[LegacyXML_ShredResponseQueue]
			([//HWTRepository/LegacyXML/ShredContract])
;
GO

CREATE	SERVICE [//HWTRepository/LegacyXML/ShredRequestService]
		ON QUEUE xmlStage.[LegacyXML_ShredRequestQueue]
			([//HWTRepository/LegacyXML/ShredContract])
;
