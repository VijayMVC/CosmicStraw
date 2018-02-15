CREATE PROCEDURE 
	hwt.usp_DeleteTagsFromRepository( 
		@pUserID	sysname = NULL
	  , @pTagID	 	nvarchar(max)
	)
/*
DECLARE
	@pAction	AS 	char(06)		=	''
  , @pUserID	AS 	nvarchar(128)	=	N'ENT\carsoc3'
  , @pTags 		AS 	nvarchar(max) 	= 	N'
{ 	
	"TagTypes":
		[  
			{ 	
				"Name": "Hardware Increment"
			  , "Description": ""
			  , "Tags":
					[
						{"Name": "Inc3","Description": "","isPermanent": 1}
					  , {"Name": "Inc4","Description": "","isPermanent": 1}
					  , {"Name": "Inc5","Description": "","isPermanent": 1}
					  , {"Name": "Inc6","Description": "","isPermanent": 1}
					  , {"Name": "Inc7","Description": "","isPermanent": 1}
					  , {"Name": "Inc8","Description": "","isPermanent": 1} 
					]
			}
		  , {   
				"Name": "Fiscal Year"
			  , "Description": "Fiscal Year during which the test was executed"
			  , "Tags":
					[
						{"Name": "FY2015","Description": "","isPermanent": 1}
					  , {"Name": "FY2016","Description": "","isPermanent": 1}
					  , {"Name": "FY2017","Description": "","isPermanent": 1}
					  , {"Name": "FY2018","Description": "","isPermanent": 1}
					]
			}
		]
}'
*/
AS 
SET NOCOUNT, XACT_ABORT ON ; 

BEGIN TRY

    DECLARE
        @ErrorMessage	AS  nvarchar(max) ;

    DELETE 
		t
	FROM 
		hwt.Tag AS t 
	WHERE 
		EXISTS( 
			SELECT	1 
			FROM 	utility.ufn_SplitString( @pTagID, '|' ) AS x
			WHERE 	x.Item = t.TagID )
	; 

END TRY

BEGIN CATCH
    PRINT 'Throwing Error' ;
    IF @ErrorMessage IS NOT NULL
        THROW 60000, @ErrorMessage , 1;
    ELSE
        THROW ;
END CATCH