CREATE	FUNCTION utility.ufn_NumberList
				(
					@pHowManyNumbers	int		
				)

RETURNS TABLE WITH	SCHEMABINDING
AS

RETURN
/*
************************************************************************************************************************************

   Function:  utility.ufn_NumberList
     Author:  Chris Carson
    Purpose:  returns a list of numbers, incredibly fast

    revisor     date            description
    ---------   -----------     ----------------------------
    ccarson     2018-08-31		created

	Abstract:	create internal list of records
				return @pHowManyNumber of records in a sequentially numbered list 

  References:	http://www.sqlservercentral.com/articles/Tally+Table/72993/
				http://www.sqlservercentral.com/articles/T-SQL/74118/
				( fun ways to count quickly )

************************************************************************************************************************************
*/
	WITH	E1(N) AS
			--	10 records 
				( 
					SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
					SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
					SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
				)
		  ,	E2(N) AS( SELECT 1 FROM E1 AS A, E1 AS b )				--	10^2 
		  , E4(N) AS( SELECT 1 FROM E2 AS A, E2 AS b )				--	10^4 
		  , E8(N) AS( SELECT 1 FROM E4 AS A, E4 AS b )				--	10^8 ( this is a list of 100,000,000 records )
		  ,	En(N) AS( SELECT TOP ( @pHowManyNumbers ) 1 FROM E8 ) 

--	despite appearance, cteTally does not contain 100,000,000 rows	
--	En controls the number of records in cteTally
--		because of the way CTEs are built, only the required number
--		of records are instantiated.
--		Example:	@pHowManyNumbers = 50 so only E1 and E2 are instantiated
--					@pHowManyNumbers = 1,545,236  E8 is instantiated, but is
--						limited to only the number of records required.
					   
  SELECT	N	=	ROW_NUMBER() OVER( ORDER BY ( SELECT NULL ) ) FROM En ;
GO

