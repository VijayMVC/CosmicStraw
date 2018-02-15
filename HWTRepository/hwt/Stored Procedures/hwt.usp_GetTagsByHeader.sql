CREATE PROCEDURE 
	hwt.usp_GetTagsByHeader( 
		@pHeaderID	nvarchar(max)
	)
--
--	For a given set of headers, return assigned tags by tag type
--	Input is pipe-delimited string of header IDs 
--	Formatted input parameter is required
--
AS 

SET XACT_ABORT, NOCOUNT ON ; 

BEGIN TRY

	DECLARE 
		@ErrorMessage	nvarchar(max)	= 	NULL 
	; 

--	Validate @pHeaderID, must not be NULL 
	IF @pHeaderID IS NULL 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('Input parameter @pHeaderID must not be NULL ' ) ; 
		RAISERROR( N'Error in stored procedure', 16, 1 ) ; 
	END   
	
	IF OBJECT_ID( 'tempdb..#Tags' ) IS NOT NULL 
		DROP TABLE #Tags 
	; 

	SELECT DISTINCT 
		HeaderID	=	CONVERT( int, x.Item ) 
	  , TagTypeID	=	tType.TagTypeID 
	  , TagTypeName	=	tType.Name 
	  , Tags		=	CONVERT( nvarchar(max), NULL ) 
	INTO 
		#Tags
	FROM 
        utility.ufn_SplitString( @pHeaderID, '|' ) AS x 
	INNER JOIN 
		hwt.HeaderTag AS hTag
			ON hTag.HeaderID = CONVERT( int, x.Item )
	INNER JOIN 
		hwt.Tag AS t 
			ON t.TagID = hTag.TagID 
	INNER JOIN 
		hwt.TagType AS tType 
			ON tType.TagTypeID = t.TagTypeID 
	; 
	
	UPDATE 
		tmp 
	SET 
		Tags	=	STUFF((	SELECT		
								'|' + t.Name 
							FROM		
								hwt.Tag AS t 
							INNER JOIN	
								hwt.TagType AS tt 
									ON tt.TagTypeID = t.TagTypeID 
							INNER JOIN
								hwt.HeaderTag ht 
									ON ht.TagID = t.TagID 
							WHERE 
								ht.HeaderID = tmp.HeaderID 
									AND tt.TagTypeID = tmp.TagTypeID
							ORDER BY 
								t.Name
							FOR XML PATH('') ), 1, 1, '' )
	FROM 
		#Tags AS tmp 
	; 
	
	SELECT * FROM #Tags ; 
	
	RETURN 0 ; 

END TRY
BEGIN CATCH
	PRINT 'Throwing Error' ; 
	IF @ErrorMessage IS NOT NULL
		THROW 60000, @ErrorMessage , 1 ; 
	ELSE 
		THROW ; 
END CATCH	
