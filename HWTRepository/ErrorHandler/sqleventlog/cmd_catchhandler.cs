using System;
using System.Data;
using System.Data.SqlClient;
using System.Data.SqlTypes;
using Microsoft.SqlServer.Server;

public partial class SqlEventLog {

   // This purpose of this class is to provide an event handler, so that
   // we can capture with messages <= 16. The class accumulates the
   // messages while the command is running.
   private class MessageGatherer  {
      System.Collections.Generic.List<SqlError> _messages;

      public System.Collections.Generic.List<SqlError> messages {
         get { return this._messages;}
      }

      public MessageGatherer () {
         _messages = new System.Collections.Generic.List<SqlError>();
      }

      // This routine acts as an event handler.
      public void message_handler (Object sender,
                                   SqlInfoMessageEventArgs msg) {
          foreach (SqlError err in msg.Errors) {
              _messages.Add(err);
          }
      }

      // This method permits us to add a collection of messages; we
      // need this if there is a message with a severity > 16.
      public void add_messages (SqlErrorCollection errs) {
          foreach (SqlError err in errs) {
              _messages.Add(err);
          }
      }
   }


   [Microsoft.SqlServer.Server.SqlProcedure]
   public static SqlInt32 cmd_catchhandler (
          String     cmdtext,
          SqlInt32   procid,
          SqlBoolean trycatch,
          SqlString  quotechar,
          String     server,
          String     dbname,
          SqlString  username,
          SqlString  appname,
          SqlString  hostname
      )
   {

      // Replace the quote character with a single quote.
      if (! quotechar.IsNull) {
         cmdtext = cmdtext.Replace(quotechar.Value, "'");
      }

      // Instantiate the MessageGatherer class.
      MessageGatherer message_gatherer = new MessageGatherer();

      using (SqlConnection ctx_cn = new SqlConnection("context connection=true"))
      {
          // Open the context connection, and define an event handler for
          // messages with severity < 11. Then set the property with the
          // long name to also divert errors with severity <= 16 to the
          // event handler.
          ctx_cn.Open();
          ctx_cn.InfoMessage += message_gatherer.message_handler;
          ctx_cn.FireInfoMessageEventOnUserErrors = true;

          // Run the command over the context connection. The reason we
          // invoke a data reader and don't use ExecuteAndSend directly, is
          // that the latter is more prone to produce bad TDS which causes
          // errors in SqlClient (but not with ODBC or OLE DB).
          SqlCommand cmd = new SqlCommand(cmdtext, ctx_cn);
          cmd.CommandType = CommandType.Text;
          try {
             using (SqlDataReader reader = cmd.ExecuteReader()) {
                SqlContext.Pipe.Send(reader);
             }
          }
          catch (SqlException ex) {
             // An exception is an error with severity > 16. Add these
             // messages to the MessageGatherer so that we can handle them
             // all the same.
             message_gatherer.add_messages(ex.Errors);
          }

          // We don't want the event handler any more.
          ctx_cn.InfoMessage -= message_gatherer.message_handler;
          ctx_cn.FireInfoMessageEventOnUserErrors = false;

          // Some variables for the rest of the analysis.
          Int32  retvalue = 0;    // The return value from the procedure.
          String fullerrmsg = String.Empty; // Used when @reraise = 1.

          // Traverse the message collection. Note that despite the name
          // SqlError, not all messages are necessarily errors.
          foreach (SqlError msgobj in message_gatherer.messages) {

             // First mission is to send the message to the client. Before
             // we can do this, we need to augment the message to include
             // the message number. We don't add procedure nmae and line
             // number, because it seems to always be missing in this context.
             System.Text.StringBuilder sb = new System.Text.StringBuilder();
             if (msgobj.Class > 0) {
                sb.Append("{");
                sb.Append(msgobj.Number);
                sb.Append("} ");
             }
             sb.Append(msgobj.Message);

             // Now we compose the command string which is a single
             // RAISERROR statement.
             SqlCommand raisecmd = new SqlCommand(
                       "RAISERROR('%s', @severity, @state, @msg)", ctx_cn);
             raisecmd.Parameters.Add("@msg", SqlDbType.NVarChar, 2048);
             raisecmd.Parameters["@msg"].Value = sb.ToString();
             raisecmd.Parameters.Add("@severity", SqlDbType.TinyInt);
             raisecmd.Parameters["@severity"].Value =
                     (msgobj.Class <= 18 ? msgobj.Class : (Byte) 18);
             raisecmd.Parameters.Add("@state", SqlDbType.TinyInt);
             raisecmd.Parameters["@state"].Value = msgobj.State;

             // And send to client. It seems that a single RAISERROR does
             // not provoke that TDS error in SqlClient and SSMS.
             try {
                SqlContext.Pipe.ExecuteAndSend(raisecmd);
             }
             // Empty CATCH block, to suppress error from being re-thrown.
             catch  {}

             if (msgobj.Class >= 11) {
             // So this is an error. If the this is the first error, this
             // sets the return value. Accumulate all error messages in
             // fullerrmsg.
                if (retvalue == 0) {
                   fullerrmsg = msgobj.Message;
                   retvalue = msgobj.Number;
                }
                else {
                   fullerrmsg = string.Concat(fullerrmsg, "\r\n",
                                              msgobj.ToString());
                }

                // Log the error to sqleventlog. We always use a loopback
                // connection for this, in case there is a transaction in
                // progress. First set up the connection string.
                SqlConnectionStringBuilder loopback_string =
                      new SqlConnectionStringBuilder();
                loopback_string.DataSource = server;
                loopback_string.InitialCatalog = dbname;
                loopback_string.IntegratedSecurity = true;
                loopback_string.Enlist = false;

                using (SqlConnection loop_cn =
                          new SqlConnection(loopback_string.ConnectionString)) {

                   // We call log_insert_sp directly. We can permit this
                   // as we are part of the slog schema.
                   SqlCommand logcmd =
                          new SqlCommand("slog.log_insert_sp", loop_cn);

                   loop_cn.Open();

                   logcmd.CommandType = CommandType.StoredProcedure;

                   logcmd.Parameters.Add("@logid", SqlDbType.BigInt);
                   logcmd.Parameters["@logid"].Direction = ParameterDirection.Output;

                   logcmd.Parameters.Add("@msgid", SqlDbType.VarChar, 36);
                   logcmd.Parameters["@msgid"].Value = DBNull.Value;

                   logcmd.Parameters.Add("@errno", SqlDbType.Int);
                   logcmd.Parameters["@errno"].Value = msgobj.Number;

                   logcmd.Parameters.Add("@severity", SqlDbType.TinyInt);
                   logcmd.Parameters["@severity"].Value = msgobj.Class;

                   logcmd.Parameters.Add("@logprocid", SqlDbType.Int);
                   logcmd.Parameters["@logprocid"].Value = procid;

                   logcmd.Parameters.Add("@msgtext", SqlDbType.NVarChar, 2048);
                   logcmd.Parameters["@msgtext"].Value = msgobj.Message;

                   logcmd.Parameters.Add("@errproc", SqlDbType.NVarChar, 128);
                   logcmd.Parameters["@errproc"].Value = msgobj.Procedure;

                   logcmd.Parameters.Add("@linenum", SqlDbType.Int);
                   logcmd.Parameters["@linenum"].Value = msgobj.LineNumber;

                   logcmd.Parameters.Add("@username", SqlDbType.NVarChar, 128);
                   logcmd.Parameters["@username"].Value = username;

                   logcmd.Parameters.Add("@appname", SqlDbType.NVarChar, 128);
                   logcmd.Parameters["@appname"].Value = appname;

                   logcmd.Parameters.Add("@hostname", SqlDbType.NVarChar, 128);
                   logcmd.Parameters["@hostname"].Value = hostname;

                   logcmd.Parameters.Add("@p1", SqlDbType.NVarChar, 400);
                   logcmd.Parameters["@p1"].Value = DBNull.Value;
                   logcmd.Parameters.Add("@p2", SqlDbType.NVarChar, 400);
                   logcmd.Parameters["@p2"].Value = DBNull.Value;
                   logcmd.Parameters.Add("@p3", SqlDbType.NVarChar, 400);
                   logcmd.Parameters["@p3"].Value = DBNull.Value;
                   logcmd.Parameters.Add("@p4", SqlDbType.NVarChar, 400);
                   logcmd.Parameters["@p4"].Value = DBNull.Value;
                   logcmd.Parameters.Add("@p5", SqlDbType.NVarChar, 400);
                   logcmd.Parameters["@p5"].Value = DBNull.Value;
                   logcmd.Parameters.Add("@p6", SqlDbType.NVarChar, 400);
                   logcmd.Parameters["@p6"].Value = DBNull.Value;

                   logcmd.ExecuteNonQuery();

                   // Get the output parameter and update the command text,
                   // which has a separate procedure, as it is an add-on.
                   SqlInt64 logid = new SqlInt64((Int64) logcmd.Parameters["@logid"].Value);

                   logcmd.CommandText = "slog.add_cmdtext_sp";
                   logcmd.Parameters.Clear();
                   logcmd.Parameters.Add("@logid", SqlDbType.BigInt);
                   logcmd.Parameters["@logid"].Value = logid.Value;
                   logcmd.Parameters.Add("@cmdtext", SqlDbType.NVarChar, -1);
                   logcmd.Parameters["@cmdtext"].Value = cmdtext;
                   logcmd.ExecuteNonQuery();
                }
             }
          }

          // If called from a TRY block, we should throw an error for real
          // to ensure that TRY-CATCH in the calling T-SQL is activated.
          if (trycatch && retvalue != 0) {
             throw new Exception (fullerrmsg);
          }

          return retvalue;
      }
   }
};
