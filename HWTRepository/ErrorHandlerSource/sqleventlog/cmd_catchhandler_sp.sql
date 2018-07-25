-- This is the thin T-SQL wrapper on the CLR procedure for the CMD
-- catch handler. It fills in some information best retrievd from T-SQL
-- before calling the CLR procedure.
CREATE PROCEDURE slog.cmd_catchhandler_sp
                 @cmdtext   nvarchar(MAX),
                 @procid    int      = NULL,
                 @trycatch  bit      = 0,
                 @quotechar nchar(1) = NULL AS

DECLARE @dbname   sysname,
        @username sysname,
        @appname  sysname,
        @hostname sysname,
        @ret      int


-- Get auditing information. Since the CMD catch handler is intended
-- for admin tasks, we don't consider impersonation.
SELECT @dbname = db_name(), @username = SYSTEM_USER, @appname = app_name(),
       @hostname = host_name()

-- Call the CLR procedure.
EXEC @ret = slog.cmd_catchhandler_clr_sp @cmdtext, @procid, @trycatch,
                                  @quotechar, @@servername, @dbname,
                                  @username, @appname, @hostname
RETURN isnull(@ret, 1)