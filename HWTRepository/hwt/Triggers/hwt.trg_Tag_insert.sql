CREATE TRIGGER	
	hwt.trg_Tag_insert
		ON	hwt.Tag
		INSTEAD OF	INSERT
/*
***********************************************************************************************************************************

	  Trigger:	hwt.trg_Tag_insert
	 Abstract:	for insert, UPDATE hwt.Tag record if it exists and has been previously deleted while assigned to datasets


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
--	XACT_ABORT is on by default in triggers

BEGIN TRY

	 DECLARE	@duplicateTags	nvarchar(2048)
			  , @numTags		int
			  , @duplicateMsg	nvarchar(max) 
				;
	--	Throw an error when one or more tags are already present with IsDeleted = 0
	  SELECT 	@numTags 	=	COUNT(*) 
		FROM 	inserted AS i 
				INNER JOIN hwt.Tag AS t 
						ON t.TagID = i.TagID
	   WHERE 	t.IsDeleted = 0 
				; 
			
	IF  ( @numTags > 0 ) 
  	BEGIN
		  SELECT	@duplicateTags	=	STUFF
										(
											(
											  SELECT	',' + i.Name
												FROM	inserted AS i
														INNER JOIN	hwt.Tag AS t
																ON i.TagID = t.TagID
											   WHERE	t.IsDeleted = 0
														FOR XML PATH( '' ), TYPE
											).value( '.', 'nvarchar(max)' ), 1, 1, ''
										) 
					;

		IF( @numTags > 1 )
		  SELECT	@duplicateMsg = 'The following tag already exists: %1' ;
		ELSE
		  SELECT	@duplicateMsg = 'The following %2 tags already exist: %1' ;

		 EXECUTE	eLog.log_ProcessEventLog
						@pProcID	=	@@PROCID
					  , @pMessage	=	@duplicateMsg
					  , @p1			=	@duplicateTags
					  , @p2			=	@numTags 
					;
	END

	--	archive any tags that are going to be reset from IsDeleted = 1
	  INSERT	archive.Tag
					( TagID, TagTypeID, Name, Description, IsDeleted, UpdatedDate, UpdatedBy, VersionNumber, VersionTimestamp )
	  SELECT 	TagID				=	i.TagID				
			  , TagTypeID           =	i.TagTypeID           
			  , Name                =	i.Name                
			  , Description         =	t.Description         
			  , IsDeleted           =	t.IsDeleted           
			  , UpdatedDate         =	t.UpdatedDate         
			  , UpdatedBy           =	t.UpdatedBy           
			  , VersionNumber       =	ISNULL( a.VersionNumber, 0 ) + 1       
			  , VersionTimestamp    =	SYSDATETIME()
		FROM	inserted AS i
				INNER JOIN 	hwt.HeaderTag AS ht 
						ON 	ht.TagID = i.TagID
				
				INNER JOIN	hwt.Tag AS t 
						ON	t.TagID = i.TagID 
						
				OUTER APPLY
					(
					  SELECT	VersionNumber = MAX( a.VersionNumber ) 
						FROM 	archive.Tag AS a 
					   WHERE	a.TagID = i.TagID
					) AS a
				
	   WHERE	t.IsDeleted = 1
				;

	
	--	UPDATE IsDeleted = 0 for any tags that are currently assigned to dataset
	  UPDATE	t
		 SET	IsDeleted	=	0
			  , UpdatedBy	=	i.UpdatedBy
			  , UpdatedDate =	i.UpdatedDate
			  , Description =	REPLACE( i.Description, N' -- DELETED', N'' )
		FROM	hwt.Tag AS t
				INNER JOIN inserted AS i
						ON i.TagID = t.TagID 
	   WHERE	t.IsDeleted = 1
				;


	--	INSERT tags that do not already exist
	  INSERT	hwt.Tag
					(
						TagID, TagTypeID, Name, Description,  IsDeleted, UpdatedDate, UpdatedBy
					)

	  SELECT	TagID			=	i.TagID
			  , TagTypeID		=	i.TagTypeID
			  , Name			=	i.Name
			  , Description		=	i.Description
			  , IsDeleted		=	i.IsDeleted
			  , UpdatedDate		=	i.UpdatedDate
			  , UpdatedBy		=	i.UpdatedBy
		FROM	inserted AS i
	   WHERE	NOT EXISTS
					( SELECT 1 FROM hwt.Tag AS t WHERE t.TagID = i.TagID ) 
				;

END TRY

BEGIN CATCH
	 DECLARE	@pErrorData xml ;

	  SELECT	@pErrorData =	(
								  SELECT
											(
											  SELECT	*
												FROM	inserted
														FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'trg_Tag_insert' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
GO

DISABLE TRIGGER hwt.trg_Tag_insert ON hwt.Tag ; 
