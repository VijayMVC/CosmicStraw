  CREATE SERVICE	[//HWTRepository/LabVIEW/SQLSender]
   AUTHORIZATION	[dbo]
        ON QUEUE 	[labViewStage].[SQLMessageResponsQueue]
						([//HWTRepository/LabVIEW/SQLContract])
					;
GO

  CREATE SERVICE 	[//HWTRepository/LabVIEW/SQLTarget]
   AUTHORIZATION 	[dbo]
        ON QUEUE 	[labViewStage].[SQLMessageQueue]
						([//HWTRepository/LabVIEW/SQLContract])
					;
