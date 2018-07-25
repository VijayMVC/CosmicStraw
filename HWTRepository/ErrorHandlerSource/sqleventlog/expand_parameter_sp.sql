/*---------------------------------------------------------------------
  This is a helper routine to sqleventlog_sp that performs two things:
  1) Convert the input variant value to a string.
  2) Replace the corresponding parameter holder with the value.
  Note that if the parameter holder does not appear in the string,
  the string is returned as NULL, because there is no need to store it
  in sqleventlogparameters.
  sqleventlog_sp may call this procedure twice for each possible
  parameter, and there is an optimisation for this.
  Note: this version runs only on SQL 2008 and later. There is a different
  version for SQL 2005.
  ---------------------------------------------------------------------*/

CREATE PROCEDURE slog.expand_parameter_sp @msgtext nvarchar(2048) OUTPUT,
                                          @paramno tinyint,
                                          @v       sql_variant,
                                          @s       nvarchar(400) = NULL OUTPUT AS
SET XACT_ABORT, NOCOUNT ON

DECLARE @holder char(2) = '%' + ltrim(str(@paramno))

IF charindex(@holder, @msgtext COLLATE Latin1_General_BIN2) = 0
-- The quick way out.
BEGIN
   SELECT @s = NULL
   RETURN
END

-- Translate @v; first get the base type.
DECLARE @type sysname = convert(nvarchar(128),
                         sql_variant_property(@v, 'Basetype'))

SELECT @s = CASE WHEN @v IS NULL THEN '(null)'
                 WHEN @type IN ('float', 'real') THEN
                    CASE WHEN abs(convert(float, @v)) BETWEEN 1E-4 AND 1E6 OR
                              abs(convert(float, @v)) < 1E-9
                              -- Print large floats with many digits, but
                              -- smaller floats as decimal values.
                              THEN convert(nvarchar(23), convert(float, @v))
                              ELSE convert(nvarchar(23), convert(float, @v), 2)
                    END
                 WHEN @type = 'datetimeoffset'
                    THEN convert(char(30), convert(datetimeoffset(3), @v), 121)
                 WHEN @type LIKE '%date%' THEN
                    CASE WHEN convert(varchar(12), convert(datetime2(3), @v), 14) =
                              '00:00:00.000'
                         THEN convert(varchar(10), convert(date, @v), 121)
                         WHEN @type = 'smalldatetime'
                         THEN convert(varchar(16), convert(smalldatetime, @v), 121)
                         ELSE convert(varchar(23), convert(datetime2(3), @v), 121)
                    END
                 WHEN @type LIKE 'time'
                    THEN convert(char(12), convert(time(3), @v), 14)
                 WHEN @type LIKE '%binary' OR @type = 'timestamp'
                    THEN convert(nvarchar(400), convert(varbinary(8000), @v), 1)
                 ELSE convert(nvarchar(400), @v)
            END

SELECT @msgtext = replace(@msgtext, @holder, @s)
