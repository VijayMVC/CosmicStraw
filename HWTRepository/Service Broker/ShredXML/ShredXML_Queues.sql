  CREATE QUEUE [xmlStage].[CompareXML_RequestQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [xmlStage].[usp_CompareXML_Request], MAX_QUEUE_READERS = 1, EXECUTE AS N'dbo')
    ON [PRIMARY];


GO

  CREATE QUEUE [xmlStage].[CompareXML_ResponseQueue]
    WITH ACTIVATION (STATUS = ON, PROCEDURE_NAME = [xmlStage].[usp_CompareXML_Response], MAX_QUEUE_READERS = 1, EXECUTE AS N'dbo')
    ON [PRIMARY];


