CREATE TRIGGER	hwt.trg_Tag_update
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
    carsoc3     2018-04-27		Production release

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;
--	XACT_ABORT is on by default in triggers

BEGIN TRY

	--	INSERT archive copies of updated tags
	  INSERT 	INTO archive.Tag
					(
						TagID, TagTypeID, Name, Description, IsDeleted, UpdatedDate, UpdatedBy, VersionNumber		
					) 

	  SELECT 	TagID       	=	d.TagID       	
			  , TagTypeID   	=	d.TagTypeID   	
			  , Name        	=	d.Name        	
			  , Description		=	d.Description		
			  , IsDeleted   	=	d.IsDeleted   	
			  , UpdatedDate 	=	d.UpdatedDate 	
			  , UpdatedBy   	=	d.UpdatedBy   	
			  , VersionNumber	=	ISNULL( a.VersionNumber, 0 ) + 1	

		FROM	deleted AS d 
				INNER JOIN archive.Tag AS a 
						ON a.TagID = d.TagID ;

END TRY

BEGIN CATCH

    IF  @@TRANCOUNT > 0 ROLLBACK TRANSACTION ;
    
	 EXECUTE	eLog.log_CatchProcessing @pProcID = @@PROCID ;
	
END CATCH
