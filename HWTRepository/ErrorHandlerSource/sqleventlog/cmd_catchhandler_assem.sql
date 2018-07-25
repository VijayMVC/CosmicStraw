-- This file creates the assembly for the DDL catch handler. Since we use
-- the same keyfile as for the slog_loopback assembly, we don't have to
-- mess with keys here.
CREATE ASSEMBLY cmd_catchhandler FROM '$(CD)\cmd_catchhandler.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS
go
