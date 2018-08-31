CREATE TRIGGER	
	hwt.trg_Tag_update
		ON	hwt.Tag
		FOR	UPDATE
/*
***********************************************************************************************************************************

      Trigger:	hwt.trg_Tag_update
     Abstract:  after update, INSERTs copy of old record into archive.Tag
	
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

	--	INSERT archive copies of updated tags
	  INSERT	archive.Tag
					( TagID, TagTypeID, Name, Description, IsDeleted, UpdatedDate, UpdatedBy, VersionNumber, VersionTimestamp )
	  SELECT 	TagID       		=	d.TagID       	
			  , TagTypeID   		=	d.TagTypeID   	
			  , Name        		=	d.Name        	
			  , Description			=	d.Description		
			  , IsDeleted   		=	d.IsDeleted   	
			  , UpdatedDate 		=	d.UpdatedDate 	
			  , UpdatedBy   		=	d.UpdatedBy   	
			  , VersionNumber		=	ISNULL( a.VersionNumber, 0 ) + 1	
			  , VersionTimestamp	=	SYSDATETIME()

		FROM	deleted AS d 
				OUTER APPLY
					(
					  SELECT	VersionNumber = MAX( a.VersionNumber ) 
						FROM 	archive.Tag AS a
					   WHERE	a.TagID = d.TagID
					) AS a						
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
										  , (
											  SELECT	*
												FROM	deleted
														FOR XML PATH( 'deleted' ), TYPE, ELEMENTS XSINIL
											)
											FOR XML PATH( 'trg_Tag_update' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
GO

DISABLE TRIGGER hwt.trg_Tag_update ON hwt.Tag ; 
