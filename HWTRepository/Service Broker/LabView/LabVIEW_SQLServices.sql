CREATE SERVICE
	[//HWTRepository/LabVIEW/SQLSender]
		ON	QUEUE labViewStage.SQLSenderQueue
				([//HWTRepository/LabVIEW/SQLContract])
	;
GO

CREATE SERVICE
	[//HWTRepository/LabVIEW/SQLTarget]
		ON	QUEUE labViewStage.SQLMessageQueue
				([//HWTRepository/LabVIEW/SQLContract])
	;
