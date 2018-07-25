/*--------------------------------------------------------------------
  This file sets up a LOOPBACK linked server and cnofigures it to
  not enlist in distributed transactions.
  --------------------------------------------------------------------*/
IF EXISTS (SELECT * FROM sys.servers WHERE name = 'LOOPBACK')
   EXEC sp_dropserver 'LOOPBACK'
EXEC sp_addlinkedserver 'LOOPBACK', '', 'SQLNCLI', @@servername
EXEC sp_serveroption  'LOOPBACK', 'remote proc transaction promotion', 'false'
EXEC sp_serveroption  'LOOPBACK', 'rpc out', 'true'
