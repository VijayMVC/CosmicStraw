/*--------------------------------------------------------------------
  This is a helper procedure called by log_insert_sp to translate an
  object id to an object name. Because the user may not have permission
  to read this information, the procedure must be signed with a certificate,
  and a user created from the certificate is granted VIEW METADATA on
  database level.
  ---------------------------------------------------------------------*/

CREATE PROCEDURE slog.translate_procid_sp @procid int,
                                          @procname nvarchar(257) OUTPUT AS
SET XACT_ABORT, NOCOUNT ON

   -- Translate the object name, don't include the schema if it's dbo.
   SELECT @procname = CASE WHEN s.schema_id > 1
                           THEN s.name + '.'
                           ELSE ''
                      END + o.name
   FROM   sys.objects o
   JOIN   sys.schemas s ON o.schema_id = s.schema_id
   WHERE  o.object_id = @procid
go

-- Here comes the part where we add the certificate and sign the procedure.
-- First get a throw-away password.
DECLARE @password char(40)
SELECT @password = convert(char(36), newid()) + 'Aa1?'
DECLARE @sql nvarchar(MAX)

-- Drop any existing certificate and user.
IF EXISTS (SELECT * FROM sys.database_principals
           WHERE name = 'slog_translate_procid_sp$cert')
   DROP USER slog_translate_procid_sp$cert
IF EXISTS (SELECT * FROM sys.certificates
           WHERE name = 'slog_translate_procid_sp')
   DROP CERTIFICATE slog_translate_procid_sp

-- Construct the SQL and create the certificate.
SELECT @sql =
   ' CREATE CERTIFICATE slog_translate_procid_sp' +
   ' ENCRYPTION BY PASSWORD = ' + quotename(@password, '''') +
   ' WITH SUBJECT = ''To sign slog.get_procname'', ' +
   ' START_DATE = ''' + convert(char(8), getutcdate(), 112) + ''', ' +
   ' EXPIRY_DATE   = ''20300101''' +
   ' ADD SIGNATURE TO slog.translate_procid_sp ' +
   ' BY CERTIFICATE slog_translate_procid_sp ' +
   ' WITH PASSWORD = ' + quotename(@password, '''')
PRINT @sql
EXEC(@sql)

-- Create the user and grant permission.
CREATE USER slog_translate_procid_sp$cert
       FROM CERTIFICATE slog_translate_procid_sp
GRANT VIEW DEFINITION TO slog_translate_procid_sp$cert
go