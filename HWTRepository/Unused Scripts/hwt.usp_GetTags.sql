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
-- AS 
-- SET NOCOUNT, XACT_ABORT ON ; 

-- BEGIN TRY 

	-- DECLARE 
		-- @ErrorMessage 		AS 	nvarchar(max) ; 
/*
	DECLARE 
		@TagTypes			AS	nvarchar(max) 	=	ISNULL( JSON_QUERY( @pTags, 'lax $.TagTypes' ), 'X' )
	  , @TTName 			AS	nvarchar(100) 	=	ISNULL( JSON_VALUE( @pTags, 'lax $.TagTypes[0].Name' ), 'X' )
	  , @TTDescription 		AS	nvarchar(100) 	=	ISNULL( JSON_VALUE( @pTags, 'lax $.TagTypes[0].Description' ), 'X' )
	  , @UserID 			AS	sysname 		=	@pUserID
	  , @Action				AS	char(06) 		=	@pAction
	  , @Tags 				AS	nvarchar(max) 	=	ISNULL( JSON_QUERY( @pTags, 'lax $.TagTypes[0].Tags' ), 'X' ) 
	  , @TagsName 			AS	nvarchar(100)   =	ISNULL( JSON_VALUE( @pTags, 'lax $.TagTypes[0].Tags[0].Name' ), 'X' ) 
	  , @TagsDescription	AS  nvarchar(100)   =	ISNULL( JSON_VALUE( @pTags, 'lax $.TagTypes[0].Tags[0].Description' ), 'X' )
	  , @TagsIsPermanent	AS  nvarchar(100)   =	ISNULL( JSON_VALUE( @pTags, 'lax $.TagTypes[0].Tags[0].IsPermanent' ), 'X' )
	;
	  



	--	Validate JSON, is JSON well-formed?
	IF ISJSON( @pTags ) = 0 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('Input JSON data is malformed: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END 


	--	Validate JSON, are all fields present?
	IF @TagTypes = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- TagTypes collection missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END

	IF @Tags = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- Tags collection missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END

	IF @TTName = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- attribute TagTypes.Name missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END

	IF @TTDescription = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- attribute TagTypes.Description missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END

	IF @TagsName = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- attribute Tags.Name missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END

	IF @TagsDescription = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- attribute Tags.Description missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END

	IF @TagsIsPermanent = 'X' 
	BEGIN
		SELECT @ErrorMessage = FORMATMESSAGE('JSON Error -- attribute Tags.IsPermanent missing or improperly named: %s.', @pTags ) ; 
		RAISERROR( @pTags, 16, 1 ) ; 
	END
	
/*
	Load temp storage with values from JSON 
*/	

	IF OBJECT_ID( 'tempdb..#TagTypes' ) IS NOT NULL
		DROP TABLE #TagTypes ; 
		
	IF OBJECT_ID( 'tempdb..#Tags' ) IS NOT NULL
		DROP TABLE #Tags ; 
		
	SELECT *
	INTO #TagTypes
	FROM 
		OPENJSON ( @pTags, N'$.TagTypes' )  
	WITH(   
			Name		nvarchar(50)	
		  , Description nvarchar(200)	
		  , Tags		nvarchar(max) 	AS JSON 
	) ;
	  
	SELECT 
		TagTypeName		=	tt.Name
	  , Name			=	tags.Name
	  , Description		=   tags.Description
	  , IsPermanent		=	tags.IsPermanent
	INTO 
		#Tags
	FROM 
		#TagTypes AS tt
	CROSS APPLY 
		OPENJSON ( Tags )  
			WITH(
					Name		nvarchar(50)	'$.Name'
				  ,	Description	nvarchar(200) 	'$.Description'
				  ,	IsPermanent	tinyint 		'$.isPermanent'
			) AS tags ; 
	
	  
/*
	UPDATE / INSERT TagTypes and Tags when Action = ""
*/
	IF	@Action = ''
	BEGIN
		--	update descriptions for existing tag types
		UPDATE 
			tType
		SET 
			Description	=	tmp.Description
		  , UpdatedBy	=	@UserID
		  , UpdatedDate	=	GETDATE()
		FROM
			hwt.TagType	AS tType
		INNER JOIN
			#TagTypes AS tmp
				ON tmp.Name = tmp.Name 
					AND tmp.Description != tType.Description ;

		--	insert new tag types
		INSERT INTO
			hwt.TagType( 
				Name, Description, IsUserCreated, UpdatedBy, UpdatedDate 
			)
		SELECT 
			Name			=	tmp.Name	
		  , Description		=	tmp.Description
		  , IsUserCreated	=	CONVERT( tinyint, 1 )
		  , UpdatedBy		=	@UserID
		  , UpdatedDate		=	GETDATE()
		FROM 
			#TagTypes AS tmp
		WHERE 
			NOT EXISTS(
				SELECT 1 FROM hwt.TagType AS tt
				WHERE tt.Name = tmp.Name 
			) ; 	
			
		--	update tags where data has changed
		UPDATE 
			tags
		SET 
			Description	=	tmp.Description
		  , IsPermanent	=	tmp.IsPermanent
		  , UpdatedBy	=	@UserID
		  , UpdatedDate	=	GETDATE()
		FROM
			hwt.Tag	AS tags
		INNER JOIN 
			hwt.TagType AS tType 
				ON tType.ID = tags.TagTypeID
		INNER JOIN
			#Tags AS tmp
				ON tmp.TagTypeName = tType.Name 
					AND tmp.Name = tags.Name
		WHERE
			tmp.Description != tags.Description
				OR tmp.IsPermanent != tags.IsPermanent ;

		--	insert new tags
		INSERT INTO
			hwt.Tag( 
				TagTypeID, Name, Description, IsPermanent, IsDeleted, UpdatedBy, UpdatedDate 
			)
		SELECT 
			TagTypeID		=	tType.ID
		  , Name			=	tmp.Name	
		  , Description		=	tmp.Description
		  , IsPermanent		=	tmp.IsPermanent
		  , IsDeleted		=	0
		  , UpdatedBy		=	@UserID
		  , UpdatedDate		=	GETDATE()
		FROM 
			#Tags AS tmp
		INNER JOIN 
			hwt.TagTypes AS tType	
				ON tType.Name = tmp.TagTypeName
		WHERE 
			NOT EXISTS(
				SELECT 	1 
				FROM 	hwt.Tag AS tags 
				WHERE 	tags.TagTypeID = tType.ID 
						AND tags.Name = tmp.Name 
			) ; 	
	END

	
/*
*/
	IF	@Action = 'DELETE'
	BEGIN	
		--	delete Tags 
		DELETE 
			tags
		FROM 
			hwt.Tag AS tags 
		INNER JOIN	
			hwt.TagTypes AS tType
				ON tType.ID = tags.TagTypeID
		INNER JOIN 
			#Tags AS tmp 
				ON tmp.TagTypeName = tType.Name
					AND tmp.Name = tags.Name
		WHERE 
			tags.IsDeleted = 0 ; 
	END
*/
--RETURN ; 

--END TRY
--BEGIN CATCH
--	PRINT 'Throwing Error' ; 
--	IF @ErrorMessage IS NOT NULL
--		THROW 60000, @ErrorMessage , 1; 
--	ELSE 
--		THROW ; 
--END CATCH