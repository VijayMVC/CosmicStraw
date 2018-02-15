CREATE PROCEDURE 
	hwt.usp_AssignTagsToDatasets( 
	    @pUserID	nvarchar(128)	=	NULL
	  , @pHeaderID	nvarchar(max) 
	  , @pTagID		nvarchar(max) 
	  , @pNotes		nvarchar(200)	=	NULL
	)

--
--  Given a set of headers and set of tags, assign those tags to the dataset
--	Input parameters are pipe-delimited lists of headerIDs and TagIDs
--
AS

SET NOCOUNT, XACT_ABORT ON ;

BEGIN TRY

    DECLARE
        @ErrorMessage	AS  nvarchar(max) ;

	DROP TABLE IF EXISTS #header ;

	DROP TABLE IF EXISTS #tag ;
	
	SELECT 
		HeaderID = CONVERT( int, x.Item )
	INTO
		#header 
	FROM 
		utility.ufn_SplitString( @pHeaderID, '|' ) AS x
	; 


	SELECT 
		TagID = CONVERT( int, x.Item )
	INTO
		#tag 
	FROM 
		utility.ufn_SplitString( @pTagID, '|' ) AS x
	; 


	INSERT INTO 
		hwt.HeaderTag( 
			HeaderID
		  , TagID
		  , Notes
		  , UpdatedBy
		  , UpdatedDate 
		)
	SELECT 
		HeaderID		=	h.HeaderID 
		, TagID 		=	t.TagID 
		, Notes 		=	ISNULL( @pNotes, '' )
		, UpdatedBy		=	ISNULL( @pUserID, CURRENT_USER )
		, UpdatedDate	=	GETDATE()
	FROM 
		#header h
	CROSS JOIN 
		#tag t
; 
	
END TRY

BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1;
    ELSE
        THROW ;
END CATCH
GO

