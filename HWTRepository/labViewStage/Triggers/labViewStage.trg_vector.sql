﻿CREATE TRIGGER
    labViewStage.trg_vector
        ON labViewStage.vector
FOR INSERT, UPDATE
AS

-- invoke process to load repository with stage data

SET XACT_ABORT, NOCOUNT ON ;

DECLARE
    @ErrorMessage nvarchar(max) =   NULL ;

BEGIN TRY

    SELECT * INTO #inserted FROM inserted ;

    EXECUTE hwt.usp_LoadRepositoryFromStage @pSourceTable = 'vector' ;

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