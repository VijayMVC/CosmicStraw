/*-----------------------------------------------------------------------
  This is T-SQL statement to create the loopback procedure which itself
  is implmented in C#.
  -----------------------------------------------------------------------*/
CREATE PROCEDURE slog.loopback_sp
                 @server    sysname,
                 @dbname    sysname,
                 @logid     bigint OUTPUT,
                 @msgid     nvarchar(36),
                 @error     int,
                 @severity  tinyint,
                 @logprocid int,
                 @msgtext   nvarchar(2048),
                 @errproc   sysname,
                 @linenum   int,
                 @username  sysname,
                 @appname   nvarchar(128),
                 @hostname  nvarchar(128),
                 @p1        nvarchar(400),
                 @p2        nvarchar(400),
                 @p3        nvarchar(400),
                 @p4        nvarchar(400),
                 @p5        nvarchar(400),
                 @p6        nvarchar(400)
AS EXTERNAL NAME slog_loopback.SqlEventLog.slog_loopback
