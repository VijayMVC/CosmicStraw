CREATE TRIGGER
	labViewStage.trg_equipment_element
		ON labViewStage.equipment_element
		AFTER INSERT
/*
***********************************************************************************************************************************

	Procedure:	hwt.trg_equipment_element
	Abstract:	Loads IDs from triggering INSERT into labViewStage.PublishAudit

	Logic Summary
	-------------
	1)	Load IDs from inserted into labViewStage.PublishAudit


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		Enhanced messaging architecture
								--	changed trigger from INSTEAD OF to AFTER
								--	write IDs from INSERT into PublishAudit table

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.equipment_element' ) ;

	IF	NOT EXISTS( SELECT 1 FROM inserted )
		RETURN ;


--	1)	Load IDs from inserted into labViewStage.PublishAudit
	  INSERT	labViewStage.PublishAudit
					( ObjectID, RecordID )
	  SELECT	ObjectID	=	@ObjectID
			  , RecordID	=	ID
		FROM	inserted
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
											FOR XML PATH( 'trg_equipment_element' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
