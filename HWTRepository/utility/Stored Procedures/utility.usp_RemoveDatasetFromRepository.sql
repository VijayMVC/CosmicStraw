CREATE PROCEDURE
    utility.usp_RemoveDatasetFromRepository(
        @pHeaderID  nvarchar(max)
    )
--
--  For a given set of headers, Dump the dataset from repository
--  Input is pipe-delimited string of header IDs
--  Formatted input parameter is required
--
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

    DECLARE
        @ErrorMessage   nvarchar(max)   =   NULL
    ;

--  Validate @pHeaderID, must not be NULL
    IF @pHeaderID IS NULL
    BEGIN
        SELECT @ErrorMessage = FORMATMESSAGE('Input parameter @pHeaderID must not be NULL ' ) ;
        RAISERROR( N'Error in stored procedure', 16, 1 ) ;
    END

--  DELETE Test Errors
    DELETE
        tmp
    FROM
        hwt.TestError AS tmp
    WHERE EXISTS(
        SELECT 1 FROM hwt.Vector AS v
        INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x ON x.Item = v.HeaderID
        WHERE v.VectorID = tmp.VectorID
        )
    ;

--  DELETE Vector Results
    DELETE
        tmp
    FROM
        hwt.VectorResult AS tmp
    WHERE EXISTS(
        SELECT 1 FROM hwt.Vector AS v
        INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x ON x.Item = v.HeaderID
        WHERE v.VectorID = tmp.VectorID
        )
    ;

--  DELETE Vector Elements
    DELETE
        tmp
    FROM
        hwt.VectorElement AS tmp
    WHERE EXISTS(
        SELECT 1 FROM hwt.Vector AS v
        INNER JOIN utility.ufn_SplitString( @pHeaderID, '|' ) AS x ON x.Item = v.HeaderID
        WHERE v.VectorID = tmp.VectorID
        )
    ;

--  DELETE Vector
    DELETE
        tmp
    FROM
        hwt.Vector AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;

--  DELETE HeaderTag
    DELETE
        tmp
    FROM
        hwt.HeaderTag AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;

--  DELETE HeaderOption
    DELETE
        tmp
    FROM
        hwt.HeaderOption AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;

--  DELETE HeaderLibraryFile
    DELETE
        tmp
    FROM
        hwt.HeaderLibraryFile AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;

--  DELETE HeaderEquipment
    DELETE
        tmp
    FROM
        hwt.HeaderEquipment AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;

--  DELETE HeaderAppConst
    DELETE
        tmp
    FROM
        hwt.HeaderAppConst AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;

--  DELETE Header
    DELETE
        tmp
    FROM
        hwt.Header AS tmp
    WHERE EXISTS(
        SELECT 1 FROM utility.ufn_SplitString( @pHeaderID, '|' ) AS x
        WHERE x.Item = tmp.HeaderID
        )
    ;


    RETURN 0 ;

END TRY
BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1 ;
    ELSE
        THROW ;
END CATCH
