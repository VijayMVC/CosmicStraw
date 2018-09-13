  CREATE QUEUE [labViewStage].[SQLSenderQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [labViewStage].[usp_Process_SQLSender], MAX_QUEUE_READERS = 4, EXECUTE AS N'dbo')
    ON [PRIMARY];


GO

  CREATE QUEUE [labViewStage].[SQLMessageQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [labViewStage].[usp_Process_SQLMessage], MAX_QUEUE_READERS = 4, EXECUTE AS N'dbo')
    ON [PRIMARY];


