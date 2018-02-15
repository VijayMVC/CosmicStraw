CREATE PROCEDURE
    hwt.usp_RemoveTagsFromDatasets(
        @pHeaderID 	nvarchar(max)
      , @pTagID		nvarchar(max)
	)
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_LoadAppConstFromStage
    Abstract:   Un-assign tags from headers

    Logic Summary
    -------------
    1)  SELECT input parameters into temp storage 
    2)  DELETE tags assignments from hwt.HeaderTag

    Parameters
    ----------
    @pHeaderID 	nvarchar(max)	Pipe-delimited list of headers affected by the tag unassignement
    @pTagID		nvarchar(max)	Pipe-delimited list of tags to be unassigned from headers
	
	
    Notes
    -----


    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/	
AS

SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

    DECLARE
        @ErrorMessage	nvarchar(max) ;

    IF OBJECT_ID( 'tempdb..#hTags' ) IS NOT NULL
        DROP TABLE #hTags 
	;

--  1)  SELECT input parameters into temp storage 
    SELECT
        HeaderID    =   CONVERT( int, h.Item )
	  , TagID		=	CONVERT( int, t.Item )
    INTO
        #hTags
    FROM
        utility.ufn_SplitString( @pHeaderID, '|' ) AS h 
	CROSS JOIN 
		utility.ufn_SplitString( @pTagID, '|' ) AS t 
	;


--  2)  DELETE tags assignments from hwt.HeaderTag		
    DELETE
        hTag
    FROM
        hwt.HeaderTag AS hTag
    INNER JOIN
        #hTags AS tmp
            ON tmp.HeaderID = hTag.HeaderID
				AND tmp.TagID = hTag.TagID 
	; 
	
END TRY

BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1 ;
    ELSE
        THROW ;
END CATCH