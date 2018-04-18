CREATE VIEW		hwt.vw_AllTags
	   WITH		SCHEMABINDING 
--
--  expanded view of all avaliable tags in the system
--
AS

  SELECT 	TagTypeID			=   tType.TagTypeID
		  , TagTypeName			=   tType.Name
		  , TagID				=   tags.TagID
		  , TagName				=   tags.Name
		  , TagDescription		=   tags.Description
		  , TagIsDeleted		=   tags.IsDeleted
		  , TagIsPermanent		=	tType.IsPermanent
		  , TagTypeRestricted	=	tType.IsRestricted
	FROM 	hwt.Tag AS tags
			INNER JOIN hwt.TagType AS tType
					ON tType.TagTypeID = tags.TagTypeID ;
