-- This is T-SQL statement to create the main procedure for the CMD
-- catch handler, which is implemented in C#.
CREATE PROCEDURE slog.cmd_catchhandler_clr_sp
                 @cmdtext   nvarchar(MAX),
                 @procid    int,
                 @trycatch   bit,
                 @quotechar nchar(1),
                 @server    sysname,
                 @dbname    sysname,
                 @username  sysname,
                 @appname   sysname,
                 @hostname  sysname
AS EXTERNAL NAME cmd_catchhandler.SqlEventLog.cmd_catchhandler
