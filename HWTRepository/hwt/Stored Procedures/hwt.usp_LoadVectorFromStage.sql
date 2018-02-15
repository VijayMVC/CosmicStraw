CREATE PROCEDURE
    hwt.usp_LoadVectorFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadVectorFromStage
    Abstract:   Load changed vector data from stage to hwt.Vector

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  DELETE vector records that are unchanged from temp storage
    3)  MERGE vector changes from temp storage into hwt.Vector
    4)  INSERT tags from temp storage into hwt.Tag
    5)  MERGE new header tag data into hwt.HeaderTag

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
              , VectorNum   int
              , Loop        int
              , ReqID       nvarchar(1000)
              , StartTime   nvarchar(50)
              , EndTime     nvarchar(50)
            )
        ;

    CREATE TABLE
        #changes(
            ID              int
          , HeaderID        int
          , VectorNum       int
          , Loop            int
          , ReqID           nvarchar(1000)
          , StartTime       nvarchar(50)
          , EndTime         nvarchar(50)
          , OperatorName    nvarchar(50)
          , HWTChecksum     int
        )
    ;


--  1)  INSERT data into temp storage from trigger
    INSERT INTO
        #changes(
            ID, HeaderID, VectorNum, Loop, ReqID, StartTime
                , EndTime, OperatorName, HWTChecksum
        )
    SELECT
        i.*
      , h.OperatorName
      , HWTChecksum =   BINARY_CHECKSUM(
                            i.HeaderID
                          , i.VectorNum
                          , i.Loop
                          , i.ReqID
                          , i.StartTime
                          , i.EndTime
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
--        , HWTChecksum =   BINARY_CHECKSUM(
--                              i.HeaderID
--                            , i.VectorNum
--                            , i.Loop
--                            , i.ReqID
--                            , i.StartTime
--                            , i.EndTime
--                          )
--      FROM
--          #inserted AS i
--      INNER JOIN
--          xmlStage.header AS h
--              ON h.ID = i.HeaderID
    ;


--  2)  DELETE vector records that are unchanged from temp storage
    DELETE
        tmp
    FROM
        #changes as tmp
    WHERE
        EXISTS(
            SELECT  1
            FROM    hwt.Vector AS v
            WHERE   v.HeaderID = tmp.HeaderID
                        AND v.VectorNumber = tmp.VectorNum
                        AND v.LoopNumber = tmp.Loop
                        AND v.HWTChecksum =  tmp.HWTChecksum
        )
    ;

    --  exit if there is no data
    IF NOT EXISTS( SELECT 1 FROM #changes )
        RETURN ;


--  3)  MERGE Vector changes from temp storage into hwt.Vector
    WITH
        changes AS(
            SELECT
                VectorID        =   tmp.ID
              , HeaderID        =   tmp.HeaderID
              , VectorNumber    =   tmp.VectorNum
              , LoopNumber      =   tmp.Loop
              , StartTime       =   CONVERT( datetime, tmp.StartTime )
              , EndTime         =   NULLIF( CONVERT( datetime, tmp.EndTime ), '1900-01-01' )
              , HWTChecksum     =   tmp.HWTChecksum
              , UpdatedBy       =   tmp.OperatorName
            FROM
                #changes AS tmp
        ),
        vector AS(
            SELECT  *
            FROM    hwt.Vector AS v
            WHERE
                EXISTS( SELECT  1 FROM #changes AS tmp
                        WHERE   tmp.HeaderID = v.HeaderID
                )
        )
    MERGE INTO
        vector AS tgt
    USING
        changes AS src
            ON src.VectorID = tgt.VectorID
    WHEN MATCHED AND src.HWTChecksum <> tgt.HWTChecksum THEN
        UPDATE
        SET
            tgt.StartTime   =   src.StartTime
          , tgt.EndTime     =   src.EndTime
          , tgt.HWTChecksum =   src.HWTChecksum
          , tgt.UpdatedBy   =   src.UpdatedBy
          , tgt.UpdatedDate =   GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            VectorID, HeaderID, VectorNumber, LoopNumber, StartTime
                , EndTime, HWTChecksum, UpdatedDate, UpdatedBy
        )
        VALUES(
            src.VectorID, src.HeaderID, src.VectorNumber, src.LoopNumber, src.StartTime
                , src.EndTime, src.HWTChecksum, GETDATE(), src.UpdatedBy
        )
    ;


--  4)  Insert tags for requirements into temp storage
    DROP TABLE IF EXISTS #tags;

    SELECT
        HeaderID    =   tmp.HeaderID
      , TagTypeID   =   tType.TagTypeID
      , Name        =   tmp.ReqID
      , Description =   'Requirement loaded from test dataset'
      , UpdatedBy   =   tmp.OperatorName
      , TagID       =   CONVERT( int, NULL )
    INTO
        #tags
    FROM
        #changes AS tmp
    CROSS JOIN
        hwt.TagType AS tType
    WHERE
        tType.Name = 'ReqID'
            AND ISNULL( tmp.ReqID, '' ) != ''
    ;

    DELETE
        #tags
    WHERE
        Name IN ( N'NA', 'N/A' )
    ;


--  5)  INSERT tags from temp storage into hwt.Tag
    WITH
        newTags AS(
            SELECT DISTINCT
                 TagTypeID
               , Name
               , Description
               , UpdatedBy
            FROM
                #tags AS tmp
            WHERE
                NOT EXISTS(
                    SELECT  1
                    FROM    hwt.Tag AS tag
                    WHERE   tag.TagTypeID = tmp.TagTypeID AND tag.Name = tmp.Name
                )
        )
    INSERT INTO
        hwt.Tag(
            TagTypeID, Name, Description, IsPermanent, IsDeleted, UpdatedBy, UpdatedDate
    )
    SELECT
        TagTypeID
      , Name
      , Description
      , IsPermanent =   1
      , IsDeleted   =   0
      , UpdatedBy
      , UpdatedDate =   GETDATE()
    FROM
        newTags
    ;

    --  Apply new TagID back into temp storage
    UPDATE
        tmp
    SET
        TagID   =   tag.TagID
    FROM
        #tags AS tmp
    INNER JOIN
        hwt.Tag AS tag
            ON tag.TagTypeID = tmp.TagTypeID
                AND tag.Name = tmp.Name
    ;


--  6)  MERGE new header tag data into hwt.HeaderTag
    WITH
        src AS(
            SELECT  DISTINCT HeaderID, TagID, Description, UpdatedBy
            FROM    #tags
        ) ,

        existingHeaderTags AS(
            SELECT  *
            FROM    hwt.HeaderTag AS hTags
            WHERE   hTags.HeaderID IN ( SELECT HeaderID FROM src )
                    AND EXISTS(
                        SELECT  1
                        FROM
                            hwt.Tag AS tags
                        INNER JOIN
                            hwt.TagType AS tType
                                ON tType.TagTypeID = tags.TagTypeID
                        WHERE
                            tType.Name = 'ReqID'
                        )
        )

    MERGE INTO
        existingHeaderTags  AS tgt
    USING
        src
    ON
        src.HeaderID = tgt.HeaderID
            AND src.TagID = tgt.TagID

    WHEN NOT MATCHED BY TARGET THEN
        INSERT( HeaderID, TagID, Notes, UpdatedBy, UpdatedDate )
        VALUES( src.HeaderID, src.TagID, src.Description, src.UpdatedBy, GETDATE() )

    WHEN NOT MATCHED BY SOURCE THEN
        DELETE
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
