/*
 * SPDX-License-Identifier: GPL-3.0-or-later
 * SPDX-FileCopyrightText:  2011-2019 Matheus Fantinel
 *                          2025 Stella & Charlie (teamcons.carrd.co)
 *                          2025 Contributions from the ellie_Commons community (github.com/ellie-commons/)
 */

using Gee;

public class Reminduck.Database {

    private string get_database_path () {
        return Environment.get_user_data_dir () + "/database.db";
    }

    private void open_database (out Sqlite.Database database) {
        var connection = Sqlite.Database.open (get_database_path (), out database);

        if (connection != Sqlite.OK) {
            stderr.printf ("Can't open database: %d: %s\n", database.errcode (), database.errmsg ());
            //Gtk.main_quit();
        }
    }

    private void initialize_database () {
        Sqlite.Database db;
        open_database (out db);

        string query = """
            CREATE TABLE `reminders`(
              `description` TEXT NOT NULL,
              `time` TEXT NOT NULL,
              `recurrency_type` INTEGER NULL,
              `recurrency_interval` INTEGER NULL
            );          
        """;

        db.exec (query);
    }

    /**
    * Check we have everything
    * We can sneak updates in the database model here
    */
    public void verify_database (bool? plsbump = false) {

        // Make sure data directory is here
        File datadir = File.new_for_path (Environment.get_user_data_dir ());
        if (datadir.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (Environment.get_user_data_dir (), 0775);
        }

        // If the old database is still there, move it
        string old_path = Environment.get_user_data_dir () + "/.local/share/io.github.ellie_commons.reminduck/database.db";
        File checkpath = File.new_for_path (old_path);
        File new_path = File.new_for_path (get_database_path ());
        
        print ("Old database file: " + old_path + ": Exists: " + checkpath.query_exists (null).to_string ());
        print ("\nNew database file: " + get_database_path () + ": Exists: " + new_path.query_exists (null).to_string ());

        // The DB is in the wrong location so move it
        if (checkpath.query_exists ()) {
            try {
                print ("\nMoving DB...\n");
                checkpath.move (new_path, FileCopyFlags.OVERWRITE);

            } catch (Error e) {
                critical (e.message);
            }
        }

        initialize_database ();

        //FIXME: up this because now hours are in position 1, bump it
        if (plsbump) {
            print ("Database needs some updates. Proceeding.");

            var all_to_update = this.fetch_reminders ();
            foreach (var reminder in all_to_update) {
                print ("\n" + reminder.description + ": " + reminder.recurrency_type.to_friendly_string ());

                if (reminder.recurrency_type >= 1) {
                    reminder.recurrency_type = reminder.recurrency_type + 1;
                    print ("// Now %s".printf (reminder.recurrency_type.to_friendly_string ()));

                    upsert_reminder (reminder);
                }

            }
        }
    }

    //  private void create_new_columns() {
    //      Sqlite.Database db;
    //      open_database(out db);                

    //      //create new column (version migration)
    //      var query = "SELECT recurrency_type FROM 'reminders'";
    //      var exec_query = db.exec(query);
    //      if (exec_query != Sqlite.OK) {
    //          print("Column recurrency_type does not exist. Creating it... \n");
    //          var alter_table_query = "ALTER TABLE `reminders` ADD `recurrency_type` INTEGER NULL";
    //          db.exec(alter_table_query);
    //      }


    //      query = "SELECT recurrency_interval FROM 'reminders'";
    //      exec_query = db.exec(query);
    //      if (exec_query != Sqlite.OK) {
    //          print("Column recurrency_interval does not exist. Creating it... \n");
    //          var alter_table_query = "ALTER TABLE `reminders` ADD `recurrency_interval` INTEGER NULL";
    //          db.exec(alter_table_query);
    //      }
    //  }

    /**
     * Update a reminder. If it doesnt have a spot yet, also save it
     */
    public bool upsert_reminder (Reminder reminder) {
        var is_new = reminder.rowid == null;
        string prepared_query_str = "";

        if (is_new) {
            prepared_query_str = "INSERT INTO reminders(description, time, recurrency_type, recurrency_interval) 
                                        VALUES($DESCRIPTION, $TIME, $RECURRENCY_TYPE, $RECURRENCY_INTERVAL)";
        } else {
            prepared_query_str = "UPDATE reminders 
                SET description = $DESCRIPTION, time = $TIME, recurrency_type = $RECURRENCY_TYPE, recurrency_interval = $RECURRENCY_INTERVAL
                WHERE rowid = $ROWID";
        }

        Sqlite.Database db;
        open_database (out db);

        Sqlite.Statement stmt;

        int exec_query = db.prepare_v2 (prepared_query_str, prepared_query_str.length, out stmt);

        if (exec_query != Sqlite.OK) {
            print ("Error executing query:\n%s\n", prepared_query_str);
            return false;
        }

        int param_position = stmt.bind_parameter_index ("$DESCRIPTION");
        assert (param_position > 0);
        stmt.bind_text (param_position, reminder.description);

        param_position = stmt.bind_parameter_index ("$TIME");
        assert (param_position > 0);
        stmt.bind_text (param_position, reminder.time.to_unix ().to_string ());

        param_position = stmt.bind_parameter_index ("$RECURRENCY_TYPE");
        assert (param_position > 0);
        stmt.bind_text (param_position, ((int)reminder.recurrency_type).to_string ());

        param_position = stmt.bind_parameter_index ("$RECURRENCY_INTERVAL");
        assert (param_position > 0);
        stmt.bind_text (param_position, reminder.recurrency_interval.to_string ());

        if (!is_new) {
            param_position = stmt.bind_parameter_index ("$ROWID");
            assert (param_position > 0);
            stmt.bind_text (param_position, reminder.rowid);
        }

        exec_query = stmt.step ();
        if (exec_query != Sqlite.DONE) {
            print ("Error executing query:\n%s\n", db.errmsg ());
        }

        return true;
    }

    /**
     * Used to populate the RemindersView
     */
    public ArrayList<Reminder> fetch_reminders () {
        var result = new ArrayList<Reminder> ();

        var query = """SELECT rowid, description, time, recurrency_type, recurrency_interval
                        FROM reminders
                        ORDER BY time DESC;""";

        Sqlite.Database db;
        open_database (out db);
        string errmsg;

        var exec_query = db.exec (query, (n, v, c) => {
            var reminder = new Reminder ();
            reminder.rowid = v[0];
            reminder.description = v[1];
            reminder.time = new GLib.DateTime.from_unix_local (int64.parse (v[2]));

            if (v[3] != null) {
                reminder.recurrency_type = (RecurrencyType)int.parse (v[3]);
            }

            reminder.recurrency_interval = int.parse (v[4]);

            //FIXME: Get rid of the 0's. Remove after a while
            if (reminder.recurrency_interval == 0) {
                reminder.recurrency_interval = 1;
            }

            result.add (reminder);
            return 0;
        }, out errmsg);

        if (exec_query != Sqlite.OK) {
            print ("Error executing query. Error: \n%s\n", errmsg);
        }

        return result;
    }

    public bool delete_reminder (string row_id) {
        var query = """DELETE FROM reminders WHERE rowid = """ + row_id + """;""";

        Sqlite.Database db;
        open_database (out db);
        var exec_query = db.exec (query);

        if (exec_query != Sqlite.OK) {
            print ("Error executing query:\n%s\n", query);
            return false;
        }

        return true;
    }
}
