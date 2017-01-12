/*
* Copyright (c) 2011-2013 Yorba Foundation
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU Lesser General Public
* License as published by the Free Software Foundation; either
* version 2.1 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

public class VersionTable : DatabaseTable {
    private static VersionTable instance = null;

    private VersionTable () {
        Sqlite.Statement stmt;
        int res = db.prepare_v2 ("CREATE TABLE IF NOT EXISTS VersionTable ("
                                 + "id INTEGER PRIMARY KEY, "
                                 + "schema_version INTEGER, "
                                 + "app_version TEXT, "
                                 + "user_data TEXT NULL"
                                 + ")", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.step ();
        if (res != Sqlite.DONE)
            fatal ("create version table", res);

        set_table_name ("VersionTable");
    }

    public static VersionTable get_instance () {
        if (instance == null)
            instance = new VersionTable ();

        return instance;
    }

    public int get_version (out string app_version) {
        Sqlite.Statement stmt;
        int res = db.prepare_v2 ("SELECT schema_version, app_version FROM VersionTable ORDER BY schema_version DESC LIMIT 1",
                                 -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.step ();
        if (res != Sqlite.ROW) {
            if (res != Sqlite.DONE)
                fatal ("get_version", res);

            app_version = null;

            return -1;
        }

        app_version = stmt.column_text (1);

        return stmt.column_int (0);
    }

    public void set_version (int version, string app_version, string? user_data = null) {
        Sqlite.Statement stmt;

        string bitbucket;
        if (get_version (out bitbucket) != -1) {
            // overwrite existing row
            int res = db.prepare_v2 ("UPDATE VersionTable SET schema_version=?, app_version=?, user_data=?",
                                     -1, out stmt);
            assert (res == Sqlite.OK);
        } else {
            // insert new row
            int res = db.prepare_v2 ("INSERT INTO VersionTable (schema_version, app_version, user_data) VALUES (?,?, ?)",
                                     -1, out stmt);
            assert (res == Sqlite.OK);
        }

        int res = stmt.bind_int (1, version);
        assert (res == Sqlite.OK);
        res = stmt.bind_text (2, app_version);
        assert (res == Sqlite.OK);
        res = stmt.bind_text (3, user_data);
        assert (res == Sqlite.OK);

        res = stmt.step ();
        if (res != Sqlite.DONE)
            fatal ("set_version %d %s %s".printf (version, app_version, user_data), res);
    }

    public void update_version (int version, string app_version) {
        Sqlite.Statement stmt;
        int res = db.prepare_v2 ("UPDATE VersionTable SET schema_version=?, app_version=?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, version);
        assert (res == Sqlite.OK);
        res = stmt.bind_text (2, app_version);
        assert (res == Sqlite.OK);

        res = stmt.step ();
        if (res != Sqlite.DONE)
            fatal ("update_version %d".printf (version), res);
    }
}

