CREATE TRIGGER
    ddlDatabaseTriggerLog
        ON DATABASE
FOR
    DDL_DATABASE_LEVEL_EVENTS
--
--  Log database changes
--
AS

SET XACT_ABORT, NOCOUNT ON;

DECLARE
    @data       xml
  , @schema     sysname
  , @object     sysname
  , @eventType  sysname
;

SELECT  @data   =   EVENTDATA() ;
SELECT
    @eventType  =   @data.value( '(/EVENT_INSTANCE/EventType)[1]', 'sysname' )
  , @schema     =   @data.value( '(/EVENT_INSTANCE/SchemaName)[1]', 'sysname' )
  , @object     =   @data.value( '(/EVENT_INSTANCE/ObjectName)[1]', 'sysname' )
;

IF @object IS NOT NULL
    PRINT '  ' + @eventType + ' - ' + @schema + '.' + @object ;
ELSE
    PRINT '  ' + @eventType + ' - ' + @schema ;

IF  @eventType IS NULL
    PRINT CONVERT( nvarchar(max), @data ) ;

INSERT INTO
    utility.DatabaseLog(
        PostTime
      , DatabaseUser
      , [Event]
      , [Schema]
      , Object
      , TSQL
      , XmlEvent )
VALUES(
    GETDATE()
  , CONVERT( sysname, CURRENT_USER )
  , @eventType
  , CONVERT( sysname, @schema )
  , CONVERT( sysname, @object )
  , @data.value( '(/EVENT_INSTANCE/TSQLCommand)[1]', 'nvarchar(max)' )
  , @data )
;
GO
DISABLE TRIGGER [ddlDatabaseTriggerLog]
    ON DATABASE;



