/*--------------------------------------------------------------------
  This file creates the loopback assembly. The loopback requires
  EXTERNAL_ACCESS permission for the assembly. To achieve this we
  first need to load the key the assembly was signed with in master,
  and then create a login from the key and grant that login the
  required permissions.
     Note that the script is written under the assumption that is
   invoked through SQLCMD in build_sqleventlog.bat.
  --------------------------------------------------------------------*/
USE master
go
-- The key needs a password, but we don't need to know the password, so
-- we generate one for the occasion and forget it.
DECLARE @sql      nvarchar(MAX),
        @password char(40)
SELECT @password = convert(char(36), newid()) + 'Ab4?'

-- Generate the SQL.
SELECT @sql = 'CREATE ASYMMETRIC KEY slog_loopback FROM FILE = ' +
              '''$(CD)\keypair.snk'' ' +
              'ENCRYPTION BY PASSWORD = ''' + @password + ''''

-- Execute to create the key.
PRINT @sql
EXEC(@sql)

-- Create the login to carry the permission.
CREATE LOGIN slog_loopback$asymkey FROM ASYMMETRIC KEY slog_loopback
GRANT EXTERNAL ACCESS ASSEMBLY TO slog_loopback$asymkey
go

-- Now we can go back to our regular database and create the assembly.
USE $(SQLCMDDBNAME)
go
CREATE ASSEMBLY slog_loopback FROM '$(CD)\slog_loopback.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
go
