CREATE PROCEDURE labViewStage.usp_RestartSQLMessageQueue
/*
***********************************************************************************************************************************

	Procedure:	hwt.usp_RestartSQLMessageQueue
	Abstract:	Restarts SQLMessageQueue that has been stopped with deadlocks

	Logic Summary
	-------------
	1)	ALTER QUEUE to resume the SQLMessageQueue

	Parameters
	----------

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

	 DECLARE	@FilterDate	datetime2(3) = DATEADD( minute, -5, SYSDATETIME() ) ; 

	IF	EXISTS
			( 	SELECT 	1 
				  FROM 	eLog.EventLog 
				 WHERE 	AppName = 'Microsoft SQL Server Service Broker Activation'
							AND LogDate > @FilterDate 
							AND ErrorNumber NOT IN ( 1205, 9617 )
			) 
		BEGIN
			 EXECUTE	eLog.log_ProcessEventLog	@pProcID		=	@@PROCID
												  , @pMessage		=	N'Cannot restart SQLMessageQueue.  Poison messages detected.' 
												  , @pErrorNumber	=	60001
												  , @pRaiserror		=	1
												;
		END
			
	ALTER QUEUE labViewStage.SQLMessageQueue WITH STATUS = ON ; 
	
	RETURN 0 ; 
	
END TRY

BEGIN CATCH

	IF	( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ;

	EXECUTE eLog.log_CatchProcessing
			@pProcID = @@PROCID

	RETURN 55555 ;

END CATCH
