CREATE PROCEDURE
    hwt.usp_LoadTestErrorFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadTestErrorFromStage
    Abstract:   Load error from test to hwt.TestError and hwt.HeaderOption

    Logic Summary
    -------------
    1)  INSERT error data into hwt.TestError

    Parameters
    ----------


    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    DECLARE
        @ErrorMessage   nvarchar(max)   =   NULL
    ;

    --  define temp storage tables
    IF  1=0
        CREATE TABLE
            #inserted(
                ID          int
              , VectorID    int
              , ErrorCode   int
              , ErrorText   int
            )
        ;


--  1)  INSERT error data from trigger into hwt.TestError
    INSERT INTO
        hwt.TestError(
            VectorID, ErrorCode, ErrorText, UpdatedBy, UpdatedDate
    )
    SELECT
        tmp.VectorID, tmp.ErrorCode, tmp.ErrorText, h.OperatorName, GETDATE()
    FROM
        #inserted AS tmp
    INNER JOIN
        labViewStage.vector AS v ON v.ID = tmp.VectorID
    INNER JOIN
        labViewStage.header AS h ON h.ID = v.HeaderID
    WHERE
        NOT EXISTS(
            SELECT  1
            FROM    hwt.TestError AS te
            WHERE   te.VectorID = tmp.VectorID
                        AND te.ErrorCode = tmp.ErrorCode
                        AND te.ErrorText = tmp.ErrorText
            )
--  UNION
--      SELECT
--          tmp.VectorID, tmp.ErrorCode, tmp.ErrorText, h.OperatorName, GETDATE()
--      FROM
--          #inserted AS tmp
--      INNER JOIN
--          xmlStage.vector AS v ON v.ID = tmp.VectorID
--      INNER JOIN
--          xmlStage.header AS h ON h.ID = v.HeaderID
--      WHERE
--          NOT EXISTS(
--              SELECT  1
--              FROM    hwt.TestError AS te
--              WHERE   te.VectorID = tmp.VectorID
--                          AND te.ErrorCode = tmp.ErrorCode
--                          AND te.ErrorText = tmp.ErrorText
--              )
    ;

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
