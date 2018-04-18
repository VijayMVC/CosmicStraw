-- This files initiates the load of the cmd catchhandler add-on and
-- only drops the objects related to this add-on. It also adds the
-- cmdtext column to the sqleventlog table.
IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = object_id('slog.cmd_catchhandler_sp'))
  DROP PROCEDURE slog.cmd_catchhandler_sp

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = object_id('slog.cmd_catchhandler_clr_sp'))
  DROP PROCEDURE slog.cmd_catchhandler_clr_sp

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = object_id('slog.add_cmdtext_sp'))
  DROP PROCEDURE slog.add_cmdtext_sp

IF EXISTS (SELECT * FROM sys.assemblies WHERE name = 'cmd_catchhandler')
   DROP ASSEMBLY cmd_catchhandler

IF NOT EXISTS (SELECT *
               FROM   sys.columns
               WHERE  object_id = object_id('slog.sqleventlog')
                 AND  name = 'cmdtext')
   ALTER TABLE slog.sqleventlog ADD cmdtext nvarchar(MAX)


