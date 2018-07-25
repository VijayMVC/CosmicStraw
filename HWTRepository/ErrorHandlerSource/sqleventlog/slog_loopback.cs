// This is the C# code for slog.loopback_sp. It simply passes the input
// parameters (save for the first two) to slog.log_insert_sp.

using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;

// This attribute as well as the SecuritySafeCritical attribute just below
// is needed to permit safe assemblies to invoke this external-access
// asssembly, see further the first lines of executable code below.
[assembly: System.Security.AllowPartiallyTrustedCallers]

public partial class SqlEventLog {
   [System.Security.SecuritySafeCritical]
   [Microsoft.SqlServer.Server.SqlProcedure]
   public static void slog_loopback(
          String     server,
          String     dbname,
      out SqlInt64   logid,
          SqlString  msgid,
          SqlInt32   errno,
          SqlByte    severity,
          SqlInt32   logprocid,
          SqlString  msgtext,
          SqlString  errproc,
          SqlInt32   linenum,
          SqlString  username,
          SqlString  appname,
          SqlString  hostname,
          SqlString  p1,
          SqlString  p2,
          SqlString  p3,
          SqlString  p4,
          SqlString  p5,
          SqlString  p6)
   {

      // A tip from Adam Machanic, see http://www.codemag.com/article/0705051
      // This matters in case there is a safe CLR assembly higher on the
      // call stack.
      SqlClientPermission scp = new SqlClientPermission (
            System.Security.Permissions.PermissionState.Unrestricted);
      scp.Assert();

      // Set up the connection string. Very important: Enlist must be false!
      SqlConnectionStringBuilder cstring = new SqlConnectionStringBuilder();
      cstring.DataSource = server;
      cstring.InitialCatalog = dbname;
      cstring.IntegratedSecurity = true;
      cstring.Enlist = false;

      using (SqlConnection cnn = new SqlConnection(cstring.ConnectionString))
      {
          cnn.Open();

          // Set up the call and add all of the umpteen parameters.
          SqlCommand cmd = new SqlCommand("slog.log_insert_sp", cnn);
          cmd.CommandType = CommandType.StoredProcedure;

          cmd.Parameters.Add("@logid", SqlDbType.BigInt);
          cmd.Parameters["@logid"].Direction = ParameterDirection.Output;

          cmd.Parameters.Add("@msgid", SqlDbType.VarChar, 36);
          cmd.Parameters["@msgid"].Value = msgid;

          cmd.Parameters.Add("@errno", SqlDbType.Int);
          cmd.Parameters["@errno"].Value = errno;

          cmd.Parameters.Add("@severity", SqlDbType.TinyInt);
          cmd.Parameters["@severity"].Value = severity;

          cmd.Parameters.Add("@logprocid", SqlDbType.Int);
          cmd.Parameters["@logprocid"].Value = logprocid;

          cmd.Parameters.Add("@msgtext", SqlDbType.NVarChar, 2048);
          cmd.Parameters["@msgtext"].Value = msgtext;

          cmd.Parameters.Add("@errproc", SqlDbType.NVarChar, 128);
          cmd.Parameters["@errproc"].Value = errproc;

          cmd.Parameters.Add("@linenum", SqlDbType.Int);
          cmd.Parameters["@linenum"].Value = linenum;

          cmd.Parameters.Add("@username", SqlDbType.NVarChar, 128);
          cmd.Parameters["@username"].Value = username;

          cmd.Parameters.Add("@appname", SqlDbType.NVarChar, 128);
          cmd.Parameters["@appname"].Value = appname;

          cmd.Parameters.Add("@hostname", SqlDbType.NVarChar, 128);
          cmd.Parameters["@hostname"].Value = hostname;

          cmd.Parameters.Add("@p1", SqlDbType.NVarChar, 400);
          cmd.Parameters["@p1"].Value = p1;
          cmd.Parameters.Add("@p2", SqlDbType.NVarChar, 400);
          cmd.Parameters["@p2"].Value = p2;
          cmd.Parameters.Add("@p3", SqlDbType.NVarChar, 400);
          cmd.Parameters["@p3"].Value = p3;
          cmd.Parameters.Add("@p4", SqlDbType.NVarChar, 400);
          cmd.Parameters["@p4"].Value = p4;
          cmd.Parameters.Add("@p5", SqlDbType.NVarChar, 400);
          cmd.Parameters["@p5"].Value = p5;
          cmd.Parameters.Add("@p6", SqlDbType.NVarChar, 400);
          cmd.Parameters["@p6"].Value = p6;

          cmd.ExecuteNonQuery();

          // Get the output parameter.
          logid = new SqlInt64((Int64) cmd.Parameters["@logid"].Value);
      }
   }
};
