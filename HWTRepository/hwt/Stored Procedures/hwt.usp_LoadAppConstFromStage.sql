CREATE PROCEDURE
    hwt.usp_LoadAppConstFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadAppConstFromStage
    Abstract:   Load AppConst data from stage to hwt.AppConst and hwt.HeaderAppConst

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE AppConst from temp storage into hwt.AppConst
    3)  MERGE header AppConst from temp storage into hwt.HeaderAppConst

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
              , HeaderID    int
              , Name        nvarchar(100)
              , Type        nvarchar(50)
              , Units       nvarchar(50)
              , Value       nvarchar(1000)
            )
    ;

    CREATE TABLE
        #changes(
            ID              int
          , HeaderID        int
          , Name            nvarchar(100)
          , Type            nvarchar(50)
          , Units           nvarchar(50)
          , Value           nvarchar(50)
          , OperatorName    nvarchar(1000)
          , HWTChecksum     int
          , AppConstID      int
        )
    ;

--  1)  INSERT data into temp storage from trigger
    INSERT INTO
        #changes(
            ID, HeaderID, Name, Type, Units, Value, OperatorName, HWTChecksum
        )
    SELECT
        i.*
      , h.OperatorName
      , HWTChecksum     =   BINARY_CHECKSUM(
                                i.Name
                              , i.Type
                              , i.Units
                            )
    FROM
        #inserted AS i
    INNER JOIN
        labViewStage.header AS h
            ON h.ID = i.HeaderID
--  UNION
--      SELECT
--          i.*
--        , h.OperatorName
--        , HWTChecksum     =   BINARY_CHECKSUM(
--                                  i.Name
--                                , i.Type
--                                , i.Units
--                              )
--      FROM
--          #inserted AS i
--      INNER JOIN
--          xmlStage.header AS h
--              ON h.ID = i.HeaderID
    ;


--  2)  MERGE changed AppConst from temp storage into hwt.AppConst
    WITH
        cte AS(
            SELECT
                Name        =   tmp.Name
              , DataType    =   tmp.Type
              , Units       =   tmp.Units
              , HWTChecksum =   tmp.HWTChecksum
              , UpdatedBy   =   tmp.OperatorName
             FROM
                #changes AS tmp
        )
    MERGE INTO
        hwt.AppConst  AS tgt
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

    --  Apply AppConstID back into temp storage
    UPDATE
        tmp
    SET
        AppConstID  =   ac.AppConstID
    FROM
        #changes AS tmp
    INNER JOIN
        hwt.AppConst AS ac
            ON ac.Name = tmp.Name
                AND ac.DataType = tmp.Type
                AND ac.Units = tmp.Units
    ;


--  3)  MERGE header AppConst data from temp storage into hwt.HeaderAppConst
    WITH
        cte AS(
            SELECT
                HeaderID		=   c.HeaderID
              , AppConstID		=   ac.AppConstID
              , AppConstValue	=   c.Value
              , UpdatedBy		=   c.OperatorName
            FROM
                #changes AS c
            INNER JOIN
                hwt.AppConst AS ac
                    ON c.AppConstID = ac.AppConstID
        )
    MERGE INTO
        hwt.HeaderAppConst AS tgt
    USING
        cte AS src
            ON  src.HeaderID = tgt.HeaderID
                AND src.AppConstID = tgt.AppConstID
    WHEN MATCHED AND src.AppConstValue  <>  tgt.AppConstValue
        THEN UPDATE
            SET
                tgt.AppConstValue   =   src.AppConstValue
              , tgt.UpdatedBy		=   src.UpdatedBy
              , tgt.UpdatedDate		=   GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            HeaderID, AppConstID, AppConstValue, UpdatedBy, UpdatedDate
        )
        VALUES(
            src.HeaderID, src.AppConstID, src.AppConstValue, src.UpdatedBy, GETDATE()
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
