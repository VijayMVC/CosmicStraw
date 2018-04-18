CREATE PROCEDURE 	hwt.usp_ScrubSearchInput 
	( 
	    @pSearchField	nvarchar(50)	
	  , @pSearchInput	nvarchar(2000)	
	  , @pSearchOutput	nvarchar(2000)	OUTPUT 
	)
/*
***********************************************************************************************************************************

    Procedure:  hwt.usp_ScrubSearchInput 
    Abstract:   Given a search input, parse and format into delimited list, return error if input is not valid 

    Logic Summary
    -------------

    Parameters
    ----------
	@pSearchField	nvarchar(50)				name of search field
	@pSearchInput	nvarchar(2000)				input data for search
	@pSearchOutput	nvarchar(2000)	OUTPUT 		delimited list of valid search terms
	
	
    Notes
    -----
	@delimiter for this routine is the grave accent {`}  This is a delimiter that would not appear in input string

    Revision
    --------
    carsoc3     2018-02-01      alpha release

***********************************************************************************************************************************
*/
AS
	
SET XACT_ABORT, NOCOUNT ON ; 

BEGIN TRY

	DECLARE	@delimiter			char(01)		=	'`'
		  , @scrubErrorMessage	nvarchar(200)	=	'%1 in search field %2. Input was: %3'
		  , @error_list			nvarchar(200) ;
	
	
	IF 	( @pSearchInput IS NULL ) 
		RETURN ; 
	

--	1)	Field-specific validation

	--	DatasetID: 	only allowed characters are numerics, spaces, comma, and * as wildcard
	IF 	( @pSearchField = 'DatasetID' ) 
			AND 
		( PATINDEX( '%[^ 0-9|,*]%', @pSearchInput ) > 0 )
	BEGIN 
		 EXECUTE	eLog.log_ProcessEventLog 	
						@pProcID	=	@@PROCID
					  , @pMessage	=	@scrubErrorMessage
					  , @p1			=	N'Invalid characters'
					  , @p2			=	@pSearchField
					  , @p3			=	@pSearchInput ;
	END
	

	
--	2)	Validate matched pairs of quotation marks {"} 
	IF  EXISTS( SELECT 1 FROM utility.tvf_CountOccurrences( @pSearchInput, '"' ) WHERE ItemCount % 2 = 1 )
	BEGIN 
		 EXECUTE	eLog.log_ProcessEventLog	
						@pProcID	=	@@PROCID
					  , @pMessage	=	@scrubErrorMessage
					  , @p1			=	N'Mismatched quotation marks'
					  , @p2			=	@pSearchField
					  , @p3			=	@pSearchInput ;
	END 

	
	
--	3)	Extract search terms from @pSearchInput into temp storage
	--		extract quoted phrases as single search terms 
	--		because quotation marks must be balanced, the splitter returns quoted phrases with an even-numbered index
	DROP TABLE IF EXISTS #SearchTerms ; 
	  
	  SELECT	x.Item
	    INTO	#SearchTerms 
	    FROM	utility.ufn_SplitString( @pSearchInput, '"' ) AS x 
	   WHERE	ItemNumber % 2 = 0 
	
	UNION  
	
	--		extract non-quoted items as search terms, drops whitespace and extra commas
	--		splitter on {"} returns non-quoted items with an odd-numbered index
	--		REPLACE spaces and commas in non-quoted items with @delimiter 
	--		drop zero-length items from splitter on {@delimiter}, this drops whitespace and extra commas
	  SELECT	y.Item			
	    FROM	utility.ufn_SplitString( @pSearchInput, '"' ) AS x 
				CROSS APPLY 
					utility.ufn_SplitString( REPLACE( x.Item, ',', @delimiter ), @delimiter ) AS y
	   
	   WHERE	x.ItemNumber % 2 = 1 
					AND y.Item != '' ;
	
	
--	4)	Apply wild card % to search terms 
		--	replace asterisk with % 
		--	wrap search terms in matching %% if there is no asterisk 
		-- 	DatasetID terms are not surrounded with asterisk
	  UPDATE	#SearchTerms 
		 SET	Item	=	CASE CHARINDEX( '*', Item )
								WHEN 0 THEN	CASE @pSearchField 
												WHEN 'DatasetID' THEN Item
												ELSE '%' + Item + '%'
											END
								ELSE REPLACE( Item, '*', '%' )
							END ;
	
										
--	5)	Build delimited string from temp storage 
	  SELECT	@pSearchOutput	=	STUFF
									(
										(
											  SELECT	@delimiter + Item
												FROM	#SearchTerms
														FOR XML PATH ( '' ), TYPE
										).value('.', 'nvarchar(2000)'), 1, 1, ''
									) ;

	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) 
		ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH