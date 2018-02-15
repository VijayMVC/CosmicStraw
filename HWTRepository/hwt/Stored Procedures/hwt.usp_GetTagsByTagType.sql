CREATE PROCEDURE
    [hwt].[usp_GetTagsByTagType](
        @pCriteria  AS  nvarchar(max) = NULL
    )
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_GetTagsByTagType
    Abstract:   return tags for a given tag type ( or all types ) 

    Logic Summary
    -------------
    1)  SELECT tags based on input parameters 

    Parameters
    ----------
    @pCriteria 	nvarchar(max)	Pipe-delimited list of tag types to be selected 
								Default is N'' -- this returns all tags 

								
    Notes
    -----
	@pCriteria will accept either a list of TagTypeID values or TagType.Name values

	
    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/	
AS

SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

    DECLARE
        @ErrorMessage       AS  nvarchar(max) 
	  , @IsNumeric			AS	int 
	;

--	1)  SELECT tags based on input parameters 	
	
	SELECT TOP 1 
		@IsNumeric	= ISNUMERIC( x.Item ) 
	FROM 
		utility.ufn_SplitString( @pCriteria, '|' ) AS x
	; 

	IF @pCriteria IS NULL 
	BEGIN
		SELECT
	        TagTypeName
	      , TagID
	      , TagName
	      , TagDescription
	      , TagIsDeleted
	    FROM
	        hwt.vw_AllTags AS tags
	    ORDER BY TagTypeName, TagName 
		;

		RETURN
	END


	IF @IsNumeric = 0 
	BEGIN 
		SELECT
	        TagTypeName
	      , TagID
	      , TagName
	      , TagDescription
	      , TagIsDeleted
	    FROM
	        hwt.vw_AllTags AS tags
	    INNER JOIN
	        utility.ufn_SplitString( @pCriteria, '|' ) AS x
				ON @pCriteria IS NULL
					OR( x.Item = tags.TagTypeName ) 
	    ORDER BY TagTypeName, TagName 
		;

		RETURN ;
	END

	IF @IsNumeric = 1
	BEGIN 
		SELECT
	        TagTypeName
	      , TagID
	      , TagName
	      , TagDescription
	      , TagIsDeleted
	    FROM
	        hwt.vw_AllTags AS tags
	    INNER JOIN
	        utility.ufn_SplitString( @pCriteria, '|' ) AS x
				ON @pCriteria IS NULL
					OR( x.Item = tags.TagTypeID ) 
	    ORDER BY TagTypeName, TagName 
		;

		RETURN ;
	END



END TRY

BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1;
    ELSE
        THROW ;
END CATCH
GO

