CREATE	PROCEDURE labViewStage.usp_Load_PublishAudit
			(
				@pObjectID	int
			  , @pRecordID	xml
			)
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_Load_PublishAudit
	Abstract:	INSERTs data into labViewstage.PublishAudit

	Logic Summary
	-------------
	1)	INSERT data from parameters into labViewStage.PublishAudit

	Parameters
	----------
	@pObjectID		int		OBJECT_ID that corresponds to the table into which data was originally inserted
	@pRecordID		xml		Well-formed XML containing the IDs for the inserted data

	Notes
	-----

	Revision
	--------
	carsoc3		2018-08-31		labViewStage messaging architecture

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@lObjectID	int		=	@pObjectID
			  , @lRecordID	xml		=	@pRecordID
				;


--	1)	Begin Loop to process all enqueued messages
	  INSERT	labViewStage.PublishAudit
					( ObjectID, RecordID )
	  SELECT	ObjectID	=	@lObjectID
			  , RecordID	=	x.xmlData.value( 'RecordID[1]', 'int' )
		FROM	@lRecordID.nodes( 'root/inserted' ) AS x( xmlData )
				;

	RETURN 0 ;

END TRY
BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID	=	@@PROCID
		  , @p1			=	@pObjectID
		  , @p2			=	@pRecordID

	RETURN 55555 ;

END CATCH
