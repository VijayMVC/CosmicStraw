  CREATE SERVICE	[//HWTRepository/LabVIEW/SQLSender]
   AUTHORIZATION	[dbo]
        ON QUEUE 	[labViewStage].[SQLMessageResponseQueue]
						([//HWTRepository/LabVIEW/SQLContract])
					;
GO

  CREATE SERVICE 	[//HWTRepository/LabVIEW/SQLTarget]
   AUTHORIZATION 	[dbo]
        ON QUEUE 	[labViewStage].[SQLMessageQueue]
						([//HWTRepository/LabVIEW/SQLContract])
					;
