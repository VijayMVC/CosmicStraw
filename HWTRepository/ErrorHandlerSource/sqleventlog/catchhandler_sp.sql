 /*---------------------------------------------------------------------
  This stored procedure intended to be called from a CATCH handler.
  The procedure logs the error to sqleventlog, by default it reraises
  the error.

  Parameters:
  @procid     - Pass @@procid.
  @reraise    - Whether the SP should re-reraise the error. Default is 1.
                Sometimes you may be in an inner handler in a loop, and
                want to keep the loop going. Set to 0 in such a case.
  @errno      - Returns the error number for the original error message,
                even if the message was reraised.
  @errmsg     - Returns the original error message. Good if you want to
                write the message to a status column.
  @errmsg_aug - Returns the error message augmented with procedure and
                line number.
  ---------------------------------------------------------------------*/

CREATE PROCEDURE slog.catchhandler_sp
                 @procid        int = NULL,
                 @reraise       bit = 1,
                 @errno         int = NULL OUTPUT,
                 @errmsg        nvarchar(2048) = NULL OUTPUT,
                 @errmsg_aug    nvarchar(2048) = NULL OUTPUT AS
SET XACT_ABORT, NOCOUNT ON

BEGIN TRY

   DECLARE @crlf       char(2),
           @msg        nvarchar(2048),
           @errproc    sysname,
           @linenum    int,
           @errsev     int,
           @state      int,
           @temperrno  varchar(9)

   --  Constant for CR-LF
   SELECT @crlf = char(13) + char(10)

   -- Rollback if necessary.
   IF @@trancount > 0 ROLLBACK TRANSACTION

   -- Get contents of error functions.
   SELECT @msg     = error_message(),   @errno   = error_number(),
          @errproc = error_procedure(), @linenum = error_line(),
          @errsev  = error_severity(),  @state   = error_state()

   -- If the error was (re)raised by SqlEventLog, we should not log it,
   -- and we should reraise it as-is, unless the error was in the call.
   IF isnull(@errproc, '') NOT IN (N'catchhandler_sp', N'sqleventlog_sp') OR
      @linenum = 0
   BEGIN
      -- First log the message as-is. We request that sqleventlog_sp not to
      -- raise the error, as we will do that ourselves.
      EXEC slog.sqleventlog_sp @procid, @msg, @raiserror = 0, @msgid = NULL,
                               @severity = @errsev, @errno = @errno,
                               @errproc = @errproc, @linenum = @linenum

      -- Save the message in the output variable for the original message.
      SELECT @errmsg = @msg

      -- Augment the error message with message number, procedure and
      -- line number to help the user (who may be a developer).
      SELECT @msg = '{' + ltrim(str(@errno)) + '}' +
                    CASE WHEN @errproc IS NOT NULL
                         THEN ' Procedure ' + @errproc + ','
                         ELSE ''
                    END +
                    ' Line ' + ltrim(str(@linenum)) + @crlf + @msg

      -- And save this in the other output parameter.
      SELECT @errmsg_aug = @msg
   END
   ELSE IF @msg LIKE '{[0-9]%}%' + @crlf + '%' AND
           charindex('}', @msg) BETWEEN 3 AND 11
   BEGIN
      -- This looks like a reraised message. First extract the original
      -- error number.
      SELECT @temperrno = substring(@msg, 2, charindex('}', @msg) - 2)
      IF @temperrno NOT LIKE '%[^0-9]%'
         SELECT @errno = convert(int, @temperrno)

      -- Write to the two output variables for the error message.
      SELECT @errmsg = substring(@msg, charindex(@crlf, @msg) + 2,
                                 len(@msg)),
             @errmsg_aug  = @msg
   END
   ELSE
   BEGIN
      -- Presumably a message raised by calling sqleventlog_sp directly.
      SELECT @errmsg = @msg, @errmsg_aug = @msg
   END
END TRY
BEGIN CATCH
   -- Hopefully, this never occurs, but if it does, we try to produce both
   -- messages. If the message comes from the CATCH handler in sqleventlog,
   -- we take the message as-is, and trust that it includes the error that
   -- triggered the caller's CATCH handler.
   DECLARE @newerr nvarchar(2048)

   SELECT @newerr = error_message(), @reraise = 1

   SELECT @msg = CASE WHEN @newerr LIKE 'slog.sqleventlog_sp%'
                      THEN @newerr
                      ELSE 'slog.catchhandler_sp failed with ' + @newerr +
                           @crlf + 'Original message: ' + @msg
                 END

   -- Set ouptut variables if this has not been done.
   IF @errmsg     IS NULL SELECT @errmsg     = @msg
   IF @errmsg_aug IS NULL SELECT @errmsg_aug = @msg

   -- Avoid new error if transaction is doomed.
   IF xact_state() = -1 ROLLBACK TRANSACTION
END CATCH

-- Reaise if requested (or if an unexepected error occurred).
IF @reraise = 1
BEGIN
   -- Adjust severity if needed; plain users cannot raise level 19.
   IF @errsev > 18 SELECT @errsev = 18

   -- Pass the message as a parameter to a parameter marker to avoid that
   -- % chars cause problems.
   RAISERROR('%s', @errsev, @state, @msg)
END
