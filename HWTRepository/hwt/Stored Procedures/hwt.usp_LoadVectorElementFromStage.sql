CREATE PROCEDURE
    hwt.usp_LoadVectorElementFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadVectorElementFromStage
    Abstract:   Load changed vector elements from stage to hwt.Element and hwt.VectorElement

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE elements from temp storage into hwt.Element
    3)  MERGE vector elements into hwt.VectorElement

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
        @errorMessage   nvarchar(max)   =   NULL
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
              , Value       nvarchar(1000)
            )
        ;

    CREATE TABLE
        #changes(
            ID              int
          , VectorID        int
          , Name            nvarchar(100)
          , Type            nvarchar(50)
          , Units           nvarchar(50)
          , Value           nvarchar(1000)
          , OperatorName    nvarchar(50)
          , HWTChecksum     int
          , ElementID       int
        )
    ;

--  1)  INSERT data into temp storage from trigger
    INSERT INTO
        #changes(
            ID, VectorID, Name, Type, Units, Value
                , OperatorName, HWTChecksum
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
        labViewStage.vector AS v
            ON v.ID = i.VectorID
    INNER JOIN
        labViewStage.header AS h
            ON v.HeaderID = h.ID
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
--          xmlStage.vector AS v
--              ON v.ID = i.VectorID
--      INNER JOIN
--          xmlStage.header AS h
--              ON v.HeaderID = h.ID
    ;


--  2)  MERGE elements from temp storage into hwt.Element
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
        hwt.Element  AS tgt
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

    --  Apply ElementID back into temp storage
    UPDATE
        tmp
    SET
        ElementID   =   e.ElementID
    FROM
        #changes AS tmp
    INNER JOIN
        hwt.Element AS e
            ON e.Name = tmp.Name
    ;


--  3)  MERGE vector elements from temp storage into hwt.VectorElement
    WITH
        cte AS(
            SELECT
                VectorID		=   c.VectorID
              , ElementID		=   e.ElementID
              , ElementValue	=   c.Value
              , UpdatedBy		=   c.OperatorName
            FROM
                #changes AS c
            INNER JOIN
                hwt.Element AS e
                    ON e.ElementID = c.ElementID
        )
    MERGE INTO
        hwt.VectorElement AS tgt
    USING
        cte AS src
            ON  src.VectorID = tgt.VectorID
                AND src.ElementID = tgt.ElementID
    WHEN MATCHED AND src.ElementValue <> tgt.ElementValue
        THEN UPDATE
            SET
                tgt.ElementValue	=	src.ElementValue
              , tgt.UpdatedBy		=   src.UpdatedBy
              , tgt.UpdatedDate		=   GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            VectorID, ElementID, ElementValue, UpdatedBy, UpdatedDate
        )
        VALUES(
            src.VectorID, src.ElementID, src.ElementValue, src.UpdatedBy, GETDATE()
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
