-- This procedure is part of the CMD Catch Handler add-on, and writes the
-- cmdtext parameter to sqleventlog. If you were to use the CMD Catch Handler
-- for real, you may want to make @cmdtext a parameter to loopback_sp and
-- log_insert_sp and and scrap the procedure in this file. I have made it
-- as a separate procedure since the CMD Catch Handler is more a rough draft.
CREATE PROCEDURE slog.add_cmdtext_sp
                 @logid     bigint,
                 @cmdtext   nvarchar(MAX) AS

   UPDATE slog.sqleventlog
   SET    cmdtext = @cmdtext
   WHERE  logid = @logid

