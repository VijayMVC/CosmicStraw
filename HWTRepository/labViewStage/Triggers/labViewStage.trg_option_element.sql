CREATE TRIGGER	labViewStage.trg_option_element
			ON	labViewStage.option_element
		 AFTER	INSERT
/*
***********************************************************************************************************************************

	Procedure:	hwt.trg_option_element
	Abstract:	Loads IDs from triggering INSERT into labViewStage.PublishAudit

	Logic Summary
	-------------
	1)	Format IDs from inserted into well-formed XML
	2)	EXECUTE procedure to load data into labViewStage.PublishAudit


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		labViewStage messaging architecture
								--	changed trigger from INSTEAD OF to AFTER
								--	call proc that loads labViewStage.PublishAudit

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@ObjectID	int	=	OBJECT_ID( N'labViewStage.option_element' )
			  , @RecordID	xml
				;

	IF	NOT EXISTS( SELECT 1 FROM inserted )
		RETURN ;


--	1)	Format IDs from inserted into well-formed XML
	  SELECT	@RecordID =	(
							  SELECT	(
										  SELECT	RecordID	=	ID
											FROM	inserted
													FOR XML PATH( 'inserted' ), TYPE
										)
											FOR XML PATH( 'root' ), TYPE
							)
				;


--	2)	EXECUTE procedure to load data into labViewStage.PublishAudit
	 EXECUTE	labViewStage.usp_Load_PublishAudit
					@pObjectID	=	@ObjectID
				  , @pRecordID	=	@RecordID
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
											FOR XML PATH( 'trg_option_element' ), TYPE
								)
				;

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
