/*-------------------------------------------------------------------------
  This script creates the slog schema if it does not exists. If the schema
  exists, the script drops all objects in it as well as all assemblies,
  certificates, logins/users created for the demo.
  -------------------------------------------------------------------------*/

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'slog')
   EXEC('CREATE SCHEMA slog')
ELSE
BEGIN
   IF object_id('slog.fk_sqleventlogparameters') IS NOT NULL
      EXEC('ALTER TABLE slog.sqleventlogparameters DROP CONSTRAINT fk_sqleventlogparameters')
   DECLARE @sql nvarchar(MAX)
   DECLARE cur CURSOR STATIC LOCAL FOR
      SELECT 'DROP ' +
              CASE WHEN o.type = 'U' THEN 'TABLE'
                   WHEN o.type IN ('P', 'PC') THEN 'PROCEDURE'
                   WHEN o.type IN ('FN', 'IL', 'TF') THEN 'FUNCTION'
              END + ' slog.' + quotename(o.name)
      FROM   sys.schemas s
      JOIN   sys.objects o ON o.schema_id = s.schema_id
      WHERE  s.name = 'slog'

   OPEN cur

   WHILE 1 = 1
   BEGIN
      FETCH cur INTO @sql
      IF @@fetch_status <> 0
         BREAK

      IF @sql IS NOT NULL
      BEGIN
         PRINT @sql
         EXEC(@sql)
      END
   END

   IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'slog_loopback')
      DROP ASSEMBLY slog_loopback
   IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'cmd_catchhandler')
      DROP ASSEMBLY cmd_catchhandler
END
go
-- We also need to clean up in master
USE master
go
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = 'slog_loopback$asymkey')
   DROP LOGIN slog_loopback$asymkey
IF EXISTS (SELECT * FROM sys.asymmetric_keys WHERE name = 'slog_loopback')
   DROP ASYMMETRIC KEY slog_loopback
