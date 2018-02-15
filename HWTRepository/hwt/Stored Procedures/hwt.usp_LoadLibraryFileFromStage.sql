CREATE PROCEDURE
    hwt.usp_LoadLibraryFileFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadLibraryFileFromStage
    Abstract:   Load changed library files data from stage to hwt.LibraryFile and hwt.HeaderLibraryFile

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  MERGE test libraryFile from temp storage into hwt.LibraryFile
    3)  MERGE header library files from temp storage into hwt.HeaderLibraryFile

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
              , FileName    nvarchar(400)
              , FileRev     nvarchar(50)
              , Status      nvarchar(50)
              , HashCode    nvarchar(100)
            )
        ;

    CREATE TABLE
        #changes(
            ID              int
          , HeaderID        int
          , FileName        nvarchar(400)
          , FileRev         nvarchar(50)
          , Status          nvarchar(50)
          , HashCode        nvarchar(100)
          , OperatorName    nvarchar(50)
          , HWTChecksum     int
          , LibraryFileID   int
        )
    ;

--  1)  INSERT data into temp storage from trigger
    INSERT INTO
        #changes(
            ID, HeaderID, FileName, FileRev, Status, HashCode, OperatorName, HWTChecksum
        )
    SELECT
        i.*
      , h.OperatorName
      , HWTChecksum     =   BINARY_CHECKSUM(
                                i.FileName
                              , i.FileRev
                              , i.Status
                              , i.HashCode
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
--                                  i.FileName
--                                , i.FileRev
--                                , i.Status
--                                , i.HashCode
--                              )
--      FROM
--          #inserted AS i
--      INNER JOIN
--          xmlStage.header AS h
--              ON h.ID = i.HeaderID
    ;


--  2)  MERGE library files from temp storage into hwt.LibraryFile
    WITH
        cte AS(
            SELECT
                FileName
              , FileRev
              , Status
              , HashCode
              , HWTChecksum
              , UpdatedBy       =   tmp.OperatorName
             FROM
                #changes AS tmp
        )
    MERGE INTO
        hwt.LibraryFile  AS tgt
    USING
        cte AS src
            ON src.HWTChecksum = tgt.HWTChecksum
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            FileName, FileRev, Status, HashCode, HWTChecksum, UpdatedBy, UpdatedDate )
        VALUES(
            src.FileName, src.FileRev, src.Status, src.HashCode, src.HWTChecksum, src.UpdatedBy, GETDATE() )
    ;

    --  Apply LibraryFile back into temp storage
    UPDATE
        tmp
    SET
        LibraryFileID   =   l.LibraryFileID
    FROM
        #changes AS tmp
    INNER JOIN
        hwt.LibraryFile AS l
            ON l.HWTChecksum = tmp.HWTChecksum
    ;


--  3)  MERGE header libraryFile data from temp storage into hwt.HeaderLibraryFile
    WITH
        cte AS(
            SELECT
                HeaderID        =   c.HeaderID
              , LibraryFileID   =   c.LibraryFileID
              , UpdatedBy       =   c.OperatorName
            FROM
                #changes AS c
        )
    MERGE INTO
        hwt.HeaderLibraryFile AS tgt
    USING
        cte AS src
            ON  src.HeaderID = tgt.HeaderID
                AND src.LibraryFileID = tgt.LibraryFileID
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            HeaderID, LibraryFileID, UpdatedBy, UpdatedDate )
        VALUES(
            src.HeaderID, src.LibraryFileID, src.UpdatedBy, GETDATE() )
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
