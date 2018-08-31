CREATE VIEW
	hwt.vw_HeaderTag_expanded
--
--	expanded view of hwt.HeaderTag
--
AS

  SELECT	HeaderID		=	hTag.HeaderID
		  , TagID			=	tag.TagID
		  , TagName			=	tag.Name
		  , IsDeleted		=	tag.IsDeleted
		  , TagTypeID		=	tType.TagTypeID
		  , TagTypeName		=	tType.Name
		  , TagDescription	=	tag.Description
		  , IsPermanent		=	tType.IsPermanent
		  , IsRestricted	=	tType.IsRestricted
	FROM	hwt.Tag AS tag
			INNER JOIN	hwt.TagType AS tType
					ON	tType.TagTypeID = tag.TagTypeID

			INNER JOIN	hwt.HeaderTag AS hTag
					ON tag.TagID = hTag.TagID
			;
