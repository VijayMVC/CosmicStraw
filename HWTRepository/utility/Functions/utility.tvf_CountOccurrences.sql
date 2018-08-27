CREATE FUNCTION	utility.tvf_CountOccurrences
					( 
							@pExpression	NVARCHAR(4000)
						  , @pPattern		NVARCHAR(4000)	
					)
RETURNS TABLE WITH SCHEMABINDING
/*
************************************************************************************************************************************

	Function:  	utility.tvf_CountOccurrences
	Abstract:  	count occurrences of string @x within string @y 
   
    Logic Summary
    -------------
	1)	create tally table, max capacity 3^12 ( approx 531k )
	2)	limit tally table to max capacity DATALENGTH( [expression] )
	3) 	create input table containing [expression] 
	4)	JOIN tally table against input table on SUBSTRING to count occurrences of [pattern]
	
	
	Parameters
    ----------
	@pExpression	nvarchar(4000)	string expression to be searched
	@pPattern       nvarchar(4000)	string pattern to be searched for inside @pExpression
   
   
    revisor     date            description
    ---------   -----------     ----------------------------
    ccarson     2017-04-27      adapted and implemented 
	
	notes
	---------
	Tally Tables:	
		http://www.sqlservercentral.com/articles/Tally+Table/72993/
		http://www.sqlservercentral.com/articles/T-SQL/74118/
				
	Specific usage here with SUBSTRING 
		https://stackoverflow.com/questions/738282
	
************************************************************************************************************************************
*/
AS

RETURN


WITH 			--	tally tables max capacity of 3^12 ( approx 531k )
				E3n1( n ) AS( SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 )
			  , E3n4( n ) AS( SELECT 1 FROM E3n1 a, E3n1 b, E3n1 c, E3n1 d )
			  , E3n12( n ) AS( SELECT 1 FROM E3n4 a, E3n4 b, E3n4 c )
				
				--	actual tally table max capacity of DATALENGTH( @pExpression )
			  , En( startPos ) AS( SELECT TOP( DATALENGTH( ISNULL( @pExpression, 1 ) ) ) ROW_NUMBER() OVER( ORDER BY ( SELECT NULL ) ) FROM E3n12 )

				--	SELECT @pExpression into a cte so it can be JOINed against other tables 
			  , s( searchTarget ) AS( SELECT @pExpression )

SELECT 			ItemCount = COUNT(*) --startPos -- , Item = SUBSTRING( @pExpression, startPos, LEN(@pPattern))
FROM   			En
INNER JOIN 		s ON SUBSTRING( searchTarget, startPos, LEN(@pPattern)) = @pPattern
;
GO

