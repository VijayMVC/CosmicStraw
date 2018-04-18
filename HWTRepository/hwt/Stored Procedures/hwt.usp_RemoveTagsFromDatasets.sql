CREATE PROCEDURE	hwt.usp_RemoveTagsFromDatasets
	(
        @pUserID	sysname			=	NULL
	  , @pHeaderID 	nvarchar(max)
      , @pTagID		nvarchar(max)
	)
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_RemoveTagsFromDatasets
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

    DROP TABLE IF EXISTS #hTags ;

--  1)  SELECT input parameters into temp storage 
      SELECT	HeaderID	=   CONVERT( int, h.Item )
			  , TagID		=	CONVERT( int, t.Item )
		INTO	#hTags
		FROM	utility.ufn_SplitString( @pHeaderID, '|' ) AS h 
				CROSS JOIN 
					utility.ufn_SplitString( @pTagID, '|' ) AS t ;


--  2)  DELETE tags assignments from hwt.HeaderTag		
      DELETE	hTag
		FROM 	hwt.HeaderTag AS hTag
		
				INNER JOIN
					#hTags AS tmp
						ON tmp.HeaderID = hTag.HeaderID
							AND tmp.TagID = hTag.TagID ;
	
	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) 
		ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH