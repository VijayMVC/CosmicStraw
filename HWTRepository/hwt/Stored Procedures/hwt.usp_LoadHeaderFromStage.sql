CREATE PROCEDURE
    hwt.usp_LoadHeaderFromStage
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadHeaderFromStage
    Abstract:   Load changed header data from stage to hwt.Header

    Logic Summary
    -------------
    1)  INSERT data into temp storage from trigger
    2)  DELETE header records that are unchanged from temp storage
    3)  INSERT header tags associated with header changes
    4)  MERGE header changes from temp storage into hwt.Header
    5)  INSERT tags from temp storage into hwt.Tag
    6)  MERGE new header tag data into hwt.HeaderTag

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
                ID                  int
              , ResultFile          nvarchar(1000)
              , StartTime           nvarchar(100)
              , FinishTime          nvarchar(100)
              , TestDuration        nvarchar(100)
              , ProjectName         nvarchar(100)
              , FirmwareRev         nvarchar(100)
              , HardwareRev         nvarchar(100)
              , PartSN              nvarchar(100)
              , OperatorName        nvarchar(100)
              , TestMode            nvarchar(50)
              , TestStationID       nvarchar(100)
              , TestName            nvarchar(250)
              , TestConfigFile      nvarchar(400)
              , TestCodePathName    nvarchar(400)
              , TestCodeRev         nvarchar(100)
              , HWTSysCodeRev       nvarchar(100)
              , KdrivePath          nvarchar(400)
              , Comments            nvarchar(max)
              , ExternalFileInfo    nvarchar(max)
            )
    ;

    CREATE TABLE
        #changes(
            ID                  int
          , ResultFile          nvarchar(1000)
          , StartTime           nvarchar(100)
          , FinishTime          nvarchar(100)
          , TestDuration        nvarchar(100)
          , ProjectName         nvarchar(100)
          , FirmwareRev         nvarchar(100)
          , HardwareRev         nvarchar(100)
          , PartSN              nvarchar(100)
          , OperatorName        nvarchar(100)
          , TestMode            nvarchar(50)
          , TestStationID       nvarchar(100)
          , TestName            nvarchar(250)
          , TestConfigFile      nvarchar(400)
          , TestCodePathName    nvarchar(400)
          , TestCodeRev         nvarchar(100)
          , HWTSysCodeRev       nvarchar(100)
          , KdrivePath          nvarchar(400)
          , Comments            nvarchar(max)
          , ExternalFileInfo    nvarchar(max)
          , HWTChecksum         int
        )
    ;


--  1)  INSERT data into temp storage from trigger
    INSERT INTO
        #changes(
            ID, ResultFile, StartTime, FinishTime, TestDuration, ProjectName, FirmwareRev
                , HardwareRev, PartSN, OperatorName, TestMode, TestStationID, TestName
                , TestConfigFile, TestCodePathName, TestCodeRev, HWTSysCodeRev, KdrivePath
                , Comments, ExternalFileInfo, HWTChecksum
        )
    SELECT
        i.*
      , HWTChecksum =   BINARY_CHECKSUM(
                            ID
                          , ResultFile
                          , StartTime
                          , FinishTime
                          , TestDuration
                          , ProjectName
                          , FirmwareRev
                          , HardwareRev
                          , PartSN
                          , OperatorName
                          , TestMode
                          , TestStationID
                          , TestName
                          , TestConfigFile
                          , TestCodePathName
                          , TestCodeRev
                          , HWTSysCodeRev
                          , KdrivePath
                          , LEFT( Comments, 500 )
                          , LEFT( ExternalFileInfo, 500 )
                        )
    FROM
        #inserted AS i
    ;


--  2)  DELETE header records that are unchanged from temp storage
        --  HWTChecksum includes tag data, so this means that tags are also unchanged
    DELETE
        tmp
    FROM
        #changes AS tmp
    INNER JOIN
        hwt.Header as h
            ON h.HeaderID = tmp.ID
    WHERE
        h.HWTChecksum = tmp.HWTChecksum
    ;

    --  exit if no records remain ( there were no header changes )
    IF NOT EXISTS( SELECT 1 FROM #changes )
        RETURN ;


--  3)  INSERT header tags associated with header changes
    IF OBJECT_ID( 'tempdb..#tags' ) IS NOT NULL
        DROP TABLE #tags ;

    --  INSERT tags into temp storage from following header fields:
    --      OperatorName
    --      ProjectName
    --      FirmwareRevision
    --      DeviceSN
    --      TestMode
    SELECT
        HeaderID    =   tmp.ID
      , TagTypeID   =   tType.TagTypeID
      , Name        =   tmp.OperatorName
      , Description =   'Operator loaded from test dataset'
      , UpdatedBy   =   tmp.OperatorName
      , TagID       =   CONVERT( int, NULL )
    INTO
        #tags
    FROM
        #changes AS tmp
    CROSS JOIN
        hwt.TagType AS tType
    WHERE
        tType.Name = 'Operator'
            AND ISNULL( tmp.OperatorName, '' ) != ''
    UNION
/*         SELECT
            HeaderID    =   tmp.ID
          , TagTypeID   =   tType.TagTypeID
          , Name        =   tmp.ProjectName
          , Description =   N'Project loaded from test dataset'
          , UpdatedBy   =   tmp.OperatorName
          , TagID       =   CONVERT( int, NULL )
        FROM
            #changes AS tmp
        CROSS JOIN
            hwt.TagType AS tType
        WHERE
            tType.Name = 'Project'
                AND ISNULL( tmp.ProjectName, '' ) != '' 
    UNION */
        SELECT
            HeaderID    =   tmp.ID
          , TagTypeID   =   tType.TagTypeID
          , Name        =   tmp.FirmwareRev
          , Description =   N'Firmware Rev  loaded from test dataset'
          , UpdatedBy   =   tmp.OperatorName
          , TagID       =   CONVERT( int, NULL )
        FROM
            #changes AS tmp
        CROSS JOIN
            hwt.TagType AS tType
        WHERE
            tType.Name = N'FWRevision'
                AND ISNULL( tmp.FirmwareRev, '' ) != ''
    UNION
        SELECT
            HeaderID    =   tmp.ID
          , TagTypeID   =   tType.TagTypeID
          , Name        =   tmp.PartSN
          , Description =   N'Device SN loaded from test dataset'
          , UpdatedBy   =   tmp.OperatorName
          , TagID       =   CONVERT( int, NULL )
        FROM
            #changes AS tmp
        CROSS JOIN
            hwt.TagType AS tType
        WHERE
            tType.Name = N'DeviceSN'
                AND ISNULL( tmp.PartSN, '' ) != ''
    UNION
        SELECT
            HeaderID    =   tmp.ID
          , TagTypeID   =   tType.TagTypeID
          , Name        =   tmp.TestMode
          , Description =   N'Test Mode loaded from test dataset'
          , UpdatedBy   =   tmp.OperatorName
          , TagID       =   CONVERT( int, NULL )
        FROM
            #changes AS tmp
        CROSS JOIN
            hwt.TagType AS tType
        WHERE
            tType.Name = N'TestMode'
                AND ISNULL( tmp.TestMode, '' ) != ''
/*     UNION
        SELECT
            HeaderID    =   tmp.ID
          , TagTypeID   =   tType.TagTypeID
          , Name        =   tmp.HardwareRev
          , Description =   N'Hardware Increment loaded from test dataset'
          , UpdatedBy   =   tmp.OperatorName
          , TagID       =   CONVERT( int, NULL )
        FROM
            #changes AS tmp
        CROSS JOIN
            hwt.TagType AS tType
        WHERE
            tType.Name = N'HWIncrement'
                AND ISNULL( tmp.HardwareRev, '' ) != '' */
    ;


--  4)  MERGE header changes from temp storage into hwt.Header
    WITH
        cte AS(
            SELECT
                HeaderID            =   tmp.ID
              , ResultFileName      =   LEFT( tmp.ResultFile, 250 )
              , StartTime           =   CONVERT( datetime, tmp.StartTime )
              , FinishTime          =   NULLIF( CONVERT( datetime, tmp.FinishTime ), '1900-01-01' )
              , TestStationID       =   tmp.TestStationID
              , TestName            =   tmp.TestName
              , TestConfigFile      =   tmp.TestConfigFile
              , TestCodePathName    =   tmp.TestCodePathName
              , TestCodeRevision    =   tmp.TestCodeRev
              , HWTSysCodeRevision  =   tmp.HWTSysCodeRev
              , KdrivePath          =   tmp.KdrivePath
              , Comments            =   tmp.Comments
              , ExternalFileInfo    =   tmp.ExternalFileInfo
              , OperatorName        =   tmp.OperatorName
              , HWTChecksum         =   tmp.HWTChecksum
        FROM
            #changes AS tmp
        )
    MERGE INTO
        hwt.Header  AS tgt
    USING
        cte AS src
    ON
        src.HeaderID = tgt.HeaderID
    WHEN MATCHED THEN
        UPDATE
        SET
            tgt.ResultFileName      =   src.ResultFileName
          , tgt.StartTime           =   src.StartTime
          , tgt.FinishTime          =   src.FinishTime
          , tgt.TestStationName     =   src.TestStationID
          , tgt.TestName            =   src.TestName
          , tgt.TestConfigFile      =   src.TestConfigFile
          , tgt.TestCodePath        =   src.TestCodePathName
          , tgt.TestCodeRevision    =   src.TestCodeRevision
          , tgt.HWTSysCodeRevision  =   src.HWTSysCodeRevision
          , tgt.KdrivePath          =   src.KdrivePath
          , tgt.Comments            =   src.Comments
          , tgt.ExternalFileInfo    =   src.ExternalFileInfo
          , tgt.HWTChecksum         =   src.HWTChecksum
          , tgt.UpdatedBy           =   src.OperatorName
          , tgt.UpdatedDate         =   GETDATE()

    WHEN NOT MATCHED BY TARGET THEN
        INSERT(
            HeaderID, ResultFileName, StartTime, FinishTime, TestStationName
                , TestName, TestConfigFile, TestCodePath, TestCodeRevision
                , HWTSysCodeRevision, KdrivePath, Comments, ExternalFileInfo
                , HWTChecksum, UpdatedBy, UpdatedDate
        )
        VALUES(
            src.HeaderID, src.ResultFileName, src.StartTime, src.FinishTime, src.TestStationID
                , src.TestName, src.TestConfigFile, src.TestCodePathName, src.TestCodeRevision
                , src.HWTSysCodeRevision, src.KdrivePath, src.Comments, src.ExternalFileInfo
                , src.HWTChecksum, src.OperatorName, GETDATE()
        )
    ;


--  5)  INSERT tags from temp storage into hwt.Tag
    WITH
        newTags AS(
            SELECT
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
            SELECT  HeaderID, TagID, Description, UpdatedBy
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
                            tType.Name IN ( 'TestMode', 'Operator', /*'Project', */ 'DeviceSN', 'FWRevision'/*, 'HWIncrement'*/ )
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

--    WHEN NOT MATCHED BY SOURCE THEN
--        DELETE
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
