CREATE TRIGGER
	hwt.trg_Tag_delete
		ON	hwt.Tag
		INSTEAD OF	DELETE
/*
***********************************************************************************************************************************

	  Trigger:	hwt.trg_Tag_delete
	 Abstract:	on delete, UPDATEs hwt.Tag field IsDeleted when any entries are present on hwt.HeaderTag


	Logic Summary
	-------------

	Parameters
	----------

	Notes
	-----


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	IF	NOT EXISTS( SELECT 1 FROM deleted ) RETURN ;

	--	are any tags being deleted assigned to datasets?
	IF	EXISTS	(
				  SELECT	1
					 FROM	deleted	AS d
							INNER JOIN	hwt.HeaderTag AS ht
									ON	ht.TagID = d.TagID
				)
	BEGIN
		--	UPDATE IsDeleted = 1 for any tags that are currently assigned to dataset
		  UPDATE	t
			 SET	IsDeleted	=	1
				  , UpdatedBy	=	d.UpdatedBy
				  , UpdatedDate =	d.UpdatedDate
				  , Description =	d.Description + ' -- DELETED'
			FROM	hwt.Tag AS t
					INNER JOIN	deleted AS d
							ON	d.TagID = t.TagID

		   WHERE	EXISTS( SELECT 1 FROM hwt.HeaderTag AS hTag WHERE hTag.TagID = d.TagID )
					;

		  INSERT	archive.Tag
						( TagID, TagTypeID, Name, Description, IsDeleted, UpdatedDate, UpdatedBy, VersionNumber, VersionTimestamp )
		  SELECT	TagID				=	d.TagID
				  , TagTypeID			=	d.TagTypeID
				  , Name				=	d.Name
				  , Description			=	d.Description
				  , IsDeleted			=	d.IsDeleted
				  , UpdatedDate			=	d.UpdatedDate
				  , UpdatedBy			=	d.UpdatedBy
				  , VersionNumber		=	ISNULL( a.VersionNumber, 0 ) + 1
				  , VersionTimestamp	=	SYSDATETIME()
			FROM	deleted AS d
					OUTER APPLY
						(
						  SELECT	VersionNumber = MAX( a.VersionNumber )
							FROM	archive.Tag AS a
						   WHERE	a.TagID = d.TagID
						) AS a

		   WHERE	EXISTS( SELECT 1 FROM hwt.HeaderTag AS hTag WHERE hTag.TagID = d.TagID )
					;					;

	END


	--	INSERT archive records for tags that will be completely deleted
	  INSERT	archive.Tag
					( TagID, TagTypeID, Name, Description, IsDeleted, UpdatedDate, UpdatedBy, VersionNumber, VersionTimestamp )
	  SELECT	TagID				=	d.TagID
			  , TagTypeID			=	d.TagTypeID
			  , Name				=	d.Name
			  , Description			=	d.Description
			  , IsDeleted			=	d.IsDeleted
			  , UpdatedDate			=	d.UpdatedDate
			  , UpdatedBy			=	d.UpdatedBy
			  , VersionNumber		=	ISNULL( a.VersionNumber, 0 ) + 1
			  , VersionTimestamp	=	SYSDATETIME()
		FROM	deleted AS d
				OUTER APPLY
					(
					  SELECT	VersionNumber = MAX( a.VersionNumber )
						FROM	archive.Tag AS a
					   WHERE	a.TagID = d.TagID
					) AS a

	   WHERE	NOT EXISTS	(
							  SELECT	1
								FROM	hwt.HeaderTag AS ht
							   WHERE	ht.TagID = d.TagID
							)
				;

	 --	DELETE tags that have not been assigned to any datasets
	  DELETE	t
		FROM	hwt.Tag AS t
				INNER JOIN deleted AS d
						ON d.TagID = t.TagID

	   WHERE	NOT EXISTS	(
							  SELECT	1
								FROM	hwt.HeaderTag AS ht
							   WHERE	hT.TagID = d.TagID
							)
				;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT	(
											  SELECT	*
												FROM	deleted
														FOR XML PATH( 'deleted' ), TYPE, ELEMENTS XSINIL
											)
												FOR XML PATH( 'trg_Tag_delete' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
