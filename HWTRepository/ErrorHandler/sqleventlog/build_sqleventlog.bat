REM This file installs SqlEventLog in the chosen server and database.
REM NOTE! This file is only for SQL 2008 and later. For SQL 2005, use
REM build_sqleventlog_2005.bat.

ECHO OFF
SET SERVER=.
SET DATABASE=tempdb
PATH
REM Variable for SQLCMD. Add -U -P for SQL authentication if needed.
SET SQLCMD=SQLCMD -S %SERVER% -d %DATABASE% -I

REM First generate a key for the assembly. Comment out this line, if you
REM don't have Visual Studio.
SN -k keypair.snk
                        
REM Then build the DLL.
csc /target:library /keyfile:keypair.snk slog_loopback.cs

REM Now load all the SQL files.
%SQLCMD% -i slog_schema.sql
%SQLCMD% -i usermessages_tbl.sql
%SQLCMD% -i sqleventlog_tbl.sql
%SQLCMD% -i sqleventlogparameters_tbl.sql
%SQLCMD% -i translate_procid_sp.sql
%SQLCMD% -i log_insert_sp.sql
%SQLCMD% -i slog_loopback_assem.sql -v CD="%CD%"
%SQLCMD% -i loopback_sp.sql
%SQLCMD% -i loopback_svr.sql
%SQLCMD% -i expand_parameter_sp.sql
%SQLCMD% -i sqleventlog_sp.sql
%SQLCMD% -i catchhandler_sp.sql
