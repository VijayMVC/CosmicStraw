 /*---------------------------------------------------------------------
  This is the official interface to log a message to SqlEventLog. An
  application may want wrap this to add it's own rules. By default
  invokes RAISERROR if severity is >= 11.

  Parameters:
  @procid    - Always pass @@procid (save for wrappers).
  @msgtext   - Text for the message, may be parameterised.
  @severity  - Severity for message, default 16.
  @msgid     - Message id, defined in slog.usermessages or ad hoc.
  @raiserror - NULL => Raise only if @severity >= 11. 0 => Never
               raise. 1 => Always raise.
  @errno     - Error number to log, mainly for catchhandler_sp.
  @errproc   - Name of procedure to log, mainly for catchhandler_sp.
  @linenum   - Line number to log, mainly for catchhandler_sp.
  @p1 to @p6 - Parameters for %1 to %6 i @msgtext.
  @logid     - Returns the key for logged message in slog.sqleventlog.
  ---------------------------------------------------------------------*/

CREATE PROCEDURE slog.sqleventlog_sp
                 @procid    int,
                 @msgtext   nvarchar(2048),
                 @severity  tinyint       = 16,
                 @msgid     varchar(36)   = NULL,
                 @raiserror bit           = NULL,
                 @errno     int           = NULL,
                 @errproc   sysname       = NULL,
                 @linenum   int           = NULL,
                 @p1        sql_variant   = NULL,
                 @p2        sql_variant   = NULL,
                 @p3        sql_variant   = NULL,
                 @p4        sql_variant   = NULL,
                 @p5        sql_variant   = NULL,
                 @p6        sql_variant   = NULL,
                 @logid     bigint        = NULL OUTPUT AS
SET XACT_ABORT, NOCOUNT ON

BEGIN TRY
   DECLARE @str1     nvarchar(4000),
           @str2     nvarchar(4000),
           @str3     nvarchar(4000),
           @str4     nvarchar(4000),
           @str5     nvarchar(4000),
           @str6     nvarchar(4000),
           @username sysname,
           @appname  nvarchar(128),
           @hostname nvarchar(128)

   -- Replace the parameter holders in the message text and convert the
   -- parameter values to strings.
   IF @msgtext IS NOT NULL
   BEGIN
      EXEC slog.expand_parameter_sp @msgtext OUTPUT, 1, @p1, @str1 OUTPUT
      EXEC slog.expand_parameter_sp @msgtext OUTPUT, 2, @p2, @str2 OUTPUT
      EXEC slog.expand_parameter_sp @msgtext OUTPUT, 3, @p3, @str3 OUTPUT
      EXEC slog.expand_parameter_sp @msgtext OUTPUT, 4, @p4, @str4 OUTPUT
      EXEC slog.expand_parameter_sp @msgtext OUTPUT, 5, @p5, @str5 OUTPUT
      EXEC slog.expand_parameter_sp @msgtext OUTPUT, 6, @p6, @str6 OUTPUT
   END
   ELSE
      -- Someone is pulling our legs...
      SELECT @msgtext = 'NO MESSAGE PROVIDED!'

   -- Set values for user, application and host name. For the username, we
   -- should consider impersonation.
   SELECT @appname  = app_name(),
          @hostname = host_name(),
          @username = CASE WHEN SYSTEM_USER = original_login() OR
                                isnull(original_login(), '') = ''
                           THEN SYSTEM_USER
                           ELSE convert(nvarchar(60), SYSTEM_USER) + ' (' +
                                convert(nvarchar(60), original_login()) + ')'
                      END

   -- Now it is time to insert the message to the log table. If there is no
   -- active transaction we can insert directly.
IF @@trancount = 0
BEGIN
   EXEC slog.log_insert_sp @logid OUTPUT, @msgid, @errno, @severity,
                           @procid, @msgtext, @errproc, @linenum,
                           @username, @appname, @hostname,
                           @str1, @str2, @str3, @str4, @str5, @str6
END
   ELSE
   BEGIN
      -- We're in a transaction, so we need to do the loopback.
      DECLARE @dbname sysname
      SELECT @dbname = db_name()

      -- The loopback can be performed in two ways. The main alternative
      -- is through the CLR. loopback_sp opens a new connection and then
      -- calls log_insert_sp
      EXEC slog.loopback_sp  @@servername, @dbname,
                             @logid OUTPUT, @msgid, @errno, @severity,
                             @procid, @msgtext, @errproc, @linenum,
                             @username, @appname, @hostname,
                             @str1, @str2, @str3, @str4, @str5, @str6

      -- The alternative is to call log_insert_sp through a linked server
      -- that is set up as a loopback, and which has the option
      -- "remote proc transaction promotion" set to false. This option is
      -- not available in SQL 2005. Comment out the call above, and
      -- uncomment the below to use the loopback server.
/*    DECLARE @spname nvarchar(200) = 'LOOPBACK.' + quotename(@dbname) +
                                      '.slog.log_insert_sp'
      EXEC @spname @logid OUTPUT, @msgid, @errno, @severity,
                   @procid, @msgtext, @errproc, @linenum,
                   @username, @appname, @hostname,
                   @str1, @str2, @str3, @str4, @str5, @str6  */
   END

   -- Are we supposed to raise the error or not?
IF @raiserror = 1 OR (@raiserror IS NULL AND @severity >= 11)
BEGIN
   DECLARE @userlang smallint,
           @syslang  smallint,
           @usermsg  nvarchar(2048)

   -- In this case we should prepare a message. The RAISERROR itself
   -- is outside the TRY block.
   SELECT @raiserror = 1

   -- If there is a message id, look it up and see if there is a message
   -- directed towards the user in his own language.
   IF @msgid IS NOT NULL
   BEGIN
         -- Get the language ids to use.
         SELECT @userlang = lcid
         FROM   sys.syslanguages
         WHERE  langid = @@langid

         SELECT @syslang = l.lcid
         FROM   sys.configurations c
         JOIN   sys.syslanguages l ON c.value_in_use = l.langid
         WHERE  configuration_id = 124

         -- Then try to find the user message.
         SELECT TOP 1 @usermsg = msgtext
         FROM   usermessages
         WHERE  msgid = @msgid
           AND  lcid IN (@userlang, @syslang)
         ORDER  BY CASE lcid WHEN @userlang THEN 1 WHEN @syslang THEN 2 END

         -- If we have a user message, perform parameter subsitution.
         IF @usermsg IS NOT NULL
         BEGIN
            EXEC slog.expand_parameter_sp @usermsg OUTPUT, 1, @p1
            EXEC slog.expand_parameter_sp @usermsg OUTPUT, 2, @p2
            EXEC slog.expand_parameter_sp @usermsg OUTPUT, 3, @p3
            EXEC slog.expand_parameter_sp @usermsg OUTPUT, 4, @p4
            EXEC slog.expand_parameter_sp @usermsg OUTPUT, 5, @p5
            EXEC slog.expand_parameter_sp @usermsg OUTPUT, 6, @p6
         END
      END

      -- If we have no user message, use @msgtext.
      IF @usermsg IS NULL
         SELECT @usermsg = @msgtext
   END
END TRY
BEGIN CATCH
   -- This should not occur, but if it does we try to convey both
   -- messages. We strip the new message, because if it is a CLR message
   -- it can be very long.
   SELECT @raiserror = 1, @severity = 16,
          @usermsg = 'slog.sqleventlog_sp failed with ' +
                     substring(error_message(), 1, 800) +
                     char(13) + char(10) +
                     'Original message: ' + @msgtext

   -- Avoid new error if transaction is doomed.
   IF xact_state() = -1 ROLLBACK TRANSACTION
END CATCH

IF @raiserror = 1
BEGIN
   -- We never permit a severity > 16.
   IF @severity > 16
      SELECT @severity = 16

   -- Raise the message, and pass the message as a parameter to a parameter
   -- marker to avoid that % chars cause problems.
   RAISERROR('%s', @severity, 1, @usermsg) WITH NOWAIT
END