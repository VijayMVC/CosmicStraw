REM This file installs the CMD Catch Hadler in the chosen server and database.
REM You should first have installed SqlEventLog in the database.

ECHO OFF
SET SERVER=.
SET DATABASE=tempdb

REM Variable for SQLCMD. Add -U -P for SQL authentication if needed.
SET SQLCMD=SQLCMD -S %SERVER% -d %DATABASE% -I

csc /target:library /keyfile:keypair.snk cmd_catchhandler.cs
%SQLCMD% -i setup_cmd_catchhandler.sql
%SQLCMD% -i add_cmdtext_sp.sql
%SQLCMD% -i cmd_catchhandler_assem.sql -v CD="%CD%"
%SQLCMD% -i cmd_catchhandler_clr_sp.sql
%SQLCMD% -i cmd_catchhandler_sp.sql

