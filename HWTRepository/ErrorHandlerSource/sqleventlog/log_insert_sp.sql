/*----------------------------------------------------------------------
 This procedure performs the actual insert into the table slog.sqleventlog.
 It is not intended to be called directly, but only from sqleventlog_sp,
 possibly through a loopback arrangement. Note that this procedure
 assumes that parameter holders in @msgtext have been expanded, and that
 @username, @appname and @hostname have the correct values (it would not
 be possible for log_insert_sp to retrieve these when called in a loopback.)
  -----------------------------------------------------------------------*/
CREATE PROCEDURE slog.log_insert_sp
        @logid     bigint OUTPUT,
        @msgid     varchar(255),
        @errno     int,
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
        @p6        nvarchar(400) AS
SET XACT_ABORT, NOCOUNT ON

BEGIN TRY
   -- Translate @logprocid to a name.
   DECLARE @logproc nvarchar(257)
   EXEC slog.translate_procid_sp @logprocid, @logproc OUTPUT

   -- There is a number of coalesce here for the non-nullable columns.
   INSERT slog.sqleventlog(msgid, errno, severity, logproc,
                           msgtext, errproc, linenum,
                           username, appname, hostname)
      VALUES(@msgid, @errno, coalesce(@severity, 16), @logproc,
             coalesce(@msgtext, 'NO MESSAGE PROVIDED'), @errproc, @linenum,
             coalesce(@username, SYSTEM_USER), @appname, @hostname)

   SELECT @logid = scope_identity()

   -- Log all parameter values.
   INSERT slog.sqleventlogparameters(logid, paramno, value)
      SELECT @logid, i, p
      FROM   (SELECT 1, @p1 UNION ALL SELECT 2, @p2 UNION ALL
              SELECT 3, @p3 UNION ALL SELECT 4, @p4 UNION ALL
              SELECT 5, @p5 UNION ALL SELECT 6, @p6) AS V(i, p)
      WHERE  p IS NOT NULL
END TRY
BEGIN CATCH
   -- Hopefully we never come here...
   DECLARE @msg nvarchar(2048)
   IF xact_state() = -1 ROLLBACK TRANSACTION
   SELECT @msg = 'slog.log_insert_sp failed with "' + error_message() + '". ' +
                 'Original error: ' + @msgtext
   RAISERROR('%s', 16, 1, @msg)
END CATCH
