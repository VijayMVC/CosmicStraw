CREATE TRIGGER 	ddlDatabaseTriggerLog
			ON	DATABASE
		   FOR	DDL_DATABASE_LEVEL_EVENTS
/*
***********************************************************************************************************************************

      Trigger:	ddlDatabaseTriggerLog
     Abstract:  Logs DDL changes to permanent database change log 
	
	
    Logic Summary
    -------------
    1)	SELECT event data from system into XML variable
	2)	SELECT specific data from XML variable
	3)	INSERT change data into utility.DatabaseLog table

	
    Parameters
    ----------


    Notes
    -----

    Revision
    --------
    carsoc3     2018-02-01      alpha release
	

***********************************************************************************************************************************
*/
AS
	
SET XACT_ABORT, NOCOUNT ON ;

BEGIN TRY

	 DECLARE	@data       xml
			  , @schema     sysname
			  , @object     sysname
			  , @eventType  sysname ;

	--	1)	SELECT event data from system into XML variable
	  SELECT 	@data = EVENTDATA() ;


	--	2)	SELECT specific data from XML variable
	  SELECT	@eventType  =   @data.value( '(/EVENT_INSTANCE/EventType)[1]', 'sysname' )
			  , @schema     =   @data.value( '(/EVENT_INSTANCE/SchemaName)[1]', 'sysname' )
			  , @object     =   @data.value( '(/EVENT_INSTANCE/ObjectName)[1]', 'sysname' ) ;

	
	--	3)	INSERT change data into utility.DatabaseLog table
	  INSERT 	INTO utility.DatabaseLog
					( PostTime, DatabaseUser, [Event], [Schema], Object, TSQL, XmlEvent )
	
	  SELECT 	PostTime		=	GETDATE()
			  , DatabaseUser    =	CONVERT( sysname, CURRENT_USER )
			  , [Event]         =	@eventType
			  , [Schema]        =	CONVERT( sysname, @schema )
			  , Object          =	CONVERT( sysname, @object )
			  , TSQL            =	@data.value( '(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(max)' )
			  , XmlEvent        =	@data ;

END TRY

BEGIN CATCH

	IF( @@TRANCOUNT > 0 ) ROLLBACK TRANSACTION ; 

	EXECUTE		eLog.log_CatchProcessing 	@pProcID =	@@PROCID ;

END CATCH
GO


DISABLE TRIGGER	ddlDatabaseTriggerLog
			 ON DATABASE ;
