CREATE TRIGGER xmlStage.trg_header
    ON xmlStage.header
    FOR INSERT, UPDATE
AS

-- invoke process to load repository with stage data

SET XACT_ABORT, NOCOUNT ON ;

DECLARE
    @ErrorMessage nvarchar(max) =   NULL ;

BEGIN TRY

    SELECT * INTO #inserted FROM inserted ;

    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = 'header' ;

END TRY
BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF  @@TRANCOUNT > 0
        ROLLBACK TRANSACTION ;
    IF  @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1 ;
    ELSE
        THROW ;
END CATCH
