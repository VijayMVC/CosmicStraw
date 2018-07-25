/*------------------------------------------------------------------
  This table is a subtable to sqleventlog and holds the parameter
  values for the parameterised messages.
  ------------------------------------------------------------------*/

CREATE TABLE slog.sqleventlogparameters(
   logid    bigint        NOT NULL,
   paramno  tinyint       NOT NULL,
   value    nvarchar(400) NOT NULL,
   CONSTRAINT pk_sqleventlogparameters PRIMARY KEY (logid, paramno),
   CONSTRAINT fk_sqleventlogparameters
      FOREIGN KEY (logid) REFERENCES slog.sqleventlog(logid)
)