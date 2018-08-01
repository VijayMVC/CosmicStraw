CREATE TRIGGER	labViewStage.trg_header
			ON	labViewStage.header
		 AFTER	UPDATE
/*
***********************************************************************************************************************************

	Procedure:	hwt.trg_header
	Abstract:	Loads header records into staging environment

	Logic Summary
	-------------
	1)	RETURN when the PublishDate was the column UPDATEd 
	2)	UPDATE labViewStage.header to remove PublishDate 


	Revision
	--------
	carsoc3		2018-04-27		Production release
	carsoc3		2018-08-31		enhanced error handling
								updated messaging architecture
									--	revise trigger to AFTER UPDATE
									--	remove PublishDate from updated records

***********************************************************************************************************************************
*/
AS

SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	--	verify data was passed into the trigger
	IF	NOT EXISTS ( SELECT 1 FROM inserted )
		RETURN ;


--	1)	RETURN when the PublishDate was the column UPDATEd 		
	IF	UPDATE( PublishDate )
		RETURN ; 

--	2)	UPDATE labViewStage.header to remove PublishDate 
	  UPDATE	hdr
		 SET	PublishDate	=	NULL
		FROM	labViewStage.header AS hdr
	   WHERE	EXISTS( SELECT 1 FROM inserted AS i WHERE i.ID = hdr.ID )
				;

	RETURN ;

END TRY

BEGIN CATCH

	DECLARE	@pErrorData xml ;

	SELECT	@pErrorData =	(
							  SELECT	(
										  SELECT	*
											FROM	inserted
													FOR XML PATH( 'inserted' ), TYPE, ELEMENTS XSINIL
										)
									  , (
										  SELECT	*
											FROM	deleted
													FOR XML PATH( 'deleted' ), TYPE, ELEMENTS XSINIL
										)
										FOR XML PATH( 'trg_header' ), TYPE
							)
							;


	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	 EXECUTE	eLog.log_CatchProcessing
					@pProcID	=	@@PROCID
				  , @pErrorData =	@pErrorData
				;

END CATCH
