CREATE QUEUE [labViewStage].[SQLMessageQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [labViewStage].[usp_SQLMessage_Request], MAX_QUEUE_READERS = 5, EXECUTE AS N'dbo')
    ON [PRIMARY];

GO


	CREATE QUEUE [labViewStage].[SQLMessageResponseQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [labViewStage].[usp_SQLMessage_Response], MAX_QUEUE_READERS = 5, EXECUTE AS N'dbo')
    ON [PRIMARY];

