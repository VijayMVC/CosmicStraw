CREATE PROCEDURE
    hwt.usp_LoadVectorResultFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadVectorResultFromStage
    Abstract:   Load changed result elements from stage to hwt.Result and hwt.VectorResult

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE elements from temp storage into hwt.Result
    3)  MERGE result elements into hwt.VectorResult

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
              , Name        nvarchar(100)
              , Type        nvarchar(50)
              , Units       nvarchar(50)
              , Value       nvarchar(max)
            )
        ;

    CREATE TABLE
        #changes(
            ID              int
          , VectorID        int
          , Name            nvarchar(100)
          , Type            nvarchar(50)
          , Units           nvarchar(50)
          , ResultN         int
          , ResultValue     nvarchar(max)
          , OperatorName    nvarchar(50)
          , HWTChecksum     int
          , ResultID        int
        )
    ;


--  1)  INSERT data into temp storage from trigger
    INSERT INTO
        #changes(
            ID, VectorID, Name, Type, Units, ResultN, ResultValue, OperatorName, HWTChecksum
        )
    SELECT
        i.ID
      , i.VectorID
      , i.Name
      , i.Type
      , i.Units
      , ResultN         =   x.ItemNumber
      , ResultValue     =   x.Item
      , h.OperatorName
      , HWTChecksum     =   BINARY_CHECKSUM(
                                Name
                              , Type
                              , Units
                            )
    FROM
        #inserted AS i
    INNER JOIN
        labViewStage.vector AS v
            ON v.ID = i.VectorID
    INNER JOIN
        labViewStage.header AS h
            ON h.ID = v.HeaderID
    CROSS APPLY
        utility.ufn_SplitString( i.Value, ',' ) AS x
--  UNION
--      SELECT
--          i.ID
--        , i.VectorID
--        , i.Name
--        , i.Type
--        , i.Units
--        , ResultN         =   y.ItemNumber
--        , ResultValue     =   y.Item
--        , h.OperatorName
--        , HWTChecksum     =   BINARY_CHECKSUM(
--                                  Name
--                                , Type
--                                , Units
--                              )
--      FROM
--          #inserted AS i
--      INNER JOIN
--          xmlStage.vector AS v
--              ON v.ID = i.VectorID
--      INNER JOIN
--          xmlStage.header AS h
--              ON h.ID = v.HeaderID
--      CROSS APPLY
--          utility.ufn_SplitString( i.Value, ',' ) AS y
    ;


--  2)  MERGE elements from temp storage into hwt.Result
    WITH
        cte AS(
            SELECT DISTINCT
                Name        =   tmp.Name
              , DataType    =   tmp.Type
              , Units       =   tmp.Units
              , HWTChecksum =   tmp.HWTChecksum
              , UpdatedBy   =   tmp.OperatorName
             FROM
                #changes AS tmp
        )
    MERGE INTO
        hwt.Result  AS tgt
    USING
        cte AS src
            ON src.Name = tgt.Name
    WHEN MATCHED AND src.HWTChecksum != tgt.HWTChecksum THEN
        UPDATE
        SET
            tgt.DataType    =   src.DataType
          , tgt.Units       =   src.Units
          , tgt.HWTChecksum =   src.HWTChecksum
          , tgt.UpdatedBy   =   src.UpdatedBy
          , tgt.UpdatedDate =   GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            Name, DataType, Units, HWTChecksum, UpdatedBy, UpdatedDate
        )
        VALUES(
            src.Name, src.DataType, src.Units, src.HWTChecksum, src.UpdatedBy, GETDATE()
        )
    ;

    --  Apply ResultID back into temp storage
    UPDATE
        tmp
    SET
        ResultID    =   r.ResultID
    FROM
        #changes AS tmp
    INNER JOIN
        hwt.Result AS r
            ON r.Name = tmp.Name
    ;


--  3)  MERGE result elements from temp storage into hwt.VectorResult
    WITH
        cte AS(
            SELECT
                VectorID    =   c.VectorID
              , ResultID    =   r.ResultID
              , ResultN     =   c.ResultN
              , ResultValue =   c.ResultValue
            FROM
                #changes AS c
            INNER JOIN
                hwt.Result AS r
                    ON r.ResultID = c.ResultID
            ),
        cteVectorResult AS(
            SELECT  *
            FROM    hwt.VectorResult AS vr
            WHERE   EXISTS(
                        SELECT 1 FROM #changes AS c
                        WHERE c.VectorID = vr.VectorID AND c.ResultID = vr.ResultID )
            )
    MERGE INTO
        cteVectorResult AS tgt
    USING
        cte AS src
            ON  src.VectorID = tgt.VectorID
                AND src.ResultID = tgt.ResultID
                AND src.ResultN = tgt.ResultN
    WHEN MATCHED AND src.ResultValue <> tgt.ResultValue
        THEN UPDATE
            SET
                tgt.ResultValue =   src.ResultValue
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            VectorID, ResultID, ResultN, ResultValue
        )
        VALUES(
            src.VectorID, src.ResultID, src.ResultN, src.ResultValue
        )
    ;

    RETURN ;

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
