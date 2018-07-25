/*----------------------------------------------------------------------
  The main table for SqlEventLog where all messages are logged. This
  version runs only on SQL 2008 and later. There is a different version
  for SQL 2005.
  ----------------------------------------------------------------------*/
CREATE TABLE slog.sqleventlog (
   logid     bigint         NOT NULL IDENTITY,
   logdate   datetime2(3)   NOT NULL  -- When message was logged.
      CONSTRAINT default_slog_logdate DEFAULT sysdatetime(),
   msgid     varchar(36)    NULL,     -- A menmonic code for manually logged message, used with localisation.
   errno     int            NULL,     -- Error number for SQL Server errors.
   severity  tinyint        NOT NULL, -- Severity of the message.
   logproc   nvarchar(257)  NULL,     -- In which procedure message was logged.
   msgtext   nvarchar(2048) NOT NULL, -- Message text with parameters expanded.
   errproc   sysname        NULL,     -- In which procedure error was raised, without schema.
   linenum   int            NULL,     -- Line number in procedure.
   username  sysname        NOT NULL, -- From original_login/SYSTEM_USER.
   appname   nvarchar(128)  NULL,     -- From app_name().
   hostname  nvarchar(128)  NULL,     -- From host_name().
   CONSTRAINT pk_sqleventlog PRIMARY KEY NONCLUSTERED (logid)
)
go
CREATE CLUSTERED INDEX logdate_ix ON slog.sqleventlog (logdate)
