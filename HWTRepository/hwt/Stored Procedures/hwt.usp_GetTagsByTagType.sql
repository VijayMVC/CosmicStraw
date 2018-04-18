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

    DECLARE		@IsNumeric	int ;

--	1)  SELECT tags based on input parameters 	
	
	  SELECT 	TOP 1 
				@IsNumeric	= ISNUMERIC( x.Item ) 
		FROM  	utility.ufn_SplitString( @pCriteria, '|' ) AS x ; 

	IF 	( @pCriteria IS NULL )
		BEGIN
			  SELECT	TagTypeName
					  , TagID
					  , TagName
					  , TagDescription
					  , TagIsPermanent
					  , TagIsDeleted
					  , TagTypeRestricted
				FROM 	hwt.vw_AllTags AS tags
			   WHERE  	tags.TagIsDeleted = 0 

		   UNION ALL 
			  SELECT 	'Assets'
					  , MIN( EquipmentID * -1 )
					  , Asset + ' - ' + REPLACE( LEFT( Description, 20 ), ',', ' ' )
					  , Description
					  , 0
					  , 0
					  , 0
				FROM 	hwt.Equipment AS e
			GROUP BY	Asset + ' - ' + REPLACE( LEFT( Description, 20 ), ',', ' ' ), Description
			ORDER BY 	TagTypeName, TagName 
						;
		END


	IF 	( @IsNumeric = 0 )
	BEGIN 
			  SELECT	TagTypeName
					  , TagID
					  , TagName
					  , TagDescription
					  , TagIsPermanent
					  , TagIsDeleted
					  , TagTypeRestricted
				FROM 	hwt.vw_AllTags AS tags
						INNER JOIN utility.ufn_SplitString( @pCriteria, '|' ) AS x
								ON @pCriteria IS NULL
									OR( x.Item = tags.TagTypeName ) 				
			   WHERE  	tags.TagIsDeleted = 0 

		   UNION ALL 
			  SELECT 	'Assets'
					  , MIN( EquipmentID * -1 )
					  , Asset + ' - ' + REPLACE( LEFT( Description, 20 ), ',', ' ' )
					  , Description
					  , 0
					  , 0
					  , 0
				FROM 	hwt.Equipment AS e
						INNER JOIN utility.ufn_SplitString( @pCriteria, '|' ) AS x
								ON @pCriteria IS NULL
									OR( x.Item = 'Assets' ) 				
			GROUP BY	Asset + ' - ' + REPLACE( LEFT( Description, 20 ), ',', ' ' ), Description									
			ORDER BY 	TagTypeName, TagName 
						;

		RETURN 0 ;
	END

	IF 	( @IsNumeric = 1 )
	BEGIN 
		  SELECT 	TagTypeName
				  , TagID
				  , TagName
				  , TagDescription
				  , TagIsPermanent
				  , TagIsDeleted
				  , TagTypeRestricted
			FROM 	hwt.vw_AllTags AS tags
					INNER JOIN utility.ufn_SplitString( @pCriteria, '|' ) AS x
							ON x.Item = tags.TagTypeID
	    ORDER BY 	TagTypeName, TagName ;

		RETURN 0 ;
	END
	
END TRY

BEGIN CATCH

	IF  ( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 
		
	EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ; 
	 
	RETURN 55555 ; 

END CATCH