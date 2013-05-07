// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013 Birdie Developers (http://launchpad.net/birdie)
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@elementaryos.org>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie {

    public class SqliteDatabase : GLib.Object {

        private Sqlite.Database db;
        private string db_path;

        construct {
            int rc;
            this.db_path = Environment.get_home_dir () + "/.local/share/birdie/birdie.db";

            if (!FileUtils.test (this.db_path, FileTest.IS_REGULAR))
                rc = create_tables ();
            else
                rc = Sqlite.Database.open (this.db_path, out this.db);

            if (rc != Sqlite.OK) {
                stderr.printf ("Can't open database: %d, %s\n", rc, this.db.errmsg ());
                Gtk.main_quit ();
            }
        }

        // create tables

        private int create_tables () {
            int rc;
            debug ("Collection: Creating empty database");
            rc = Sqlite.Database.open (this.db_path, out this.db);

            // accounts table
            rc = this.db.exec ("create table accounts (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                             "screen_name VARCHAR, name VARCHAR," +
                             "token VARCHAR, token_secret VARCHAR," +
                             "avatar VARCHAR, service VARCHAR," +
                             "default_account INTEGER)", null, null);

            // cached home timeline
            // FIXME: implement table and methods for caching latest tweets

            // user completion table
            rc = this.db.exec ("create table users (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                             "screen_name VARCHAR, name VARCHAR," +
                             "account_id INTEGER)", null, null);
            return rc;
        }

        // query methods

        // set

        public void add_account (string service,
                string token, string token_secret, string? user_id = null,
                string? screen_name = null, string? name = null,
                string? avatar = null, int default_account = 1) {

            Sqlite.Statement stmt;

            reset_default_account ();

            int res = db.prepare_v2("INSERT INTO accounts (screen_name, " +
                "name, token, token_secret, avatar, service, default_account) " +
                "VALUES (?, ?, ?, ?, ?, ?, 1)", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (1, screen_name);
            assert(res == Sqlite.OK);
            res = stmt.bind_text (2, name);
            assert(res == Sqlite.OK);
            res = stmt.bind_text (3, token);
            assert(res == Sqlite.OK);
            res = stmt.bind_text (4, token_secret);
            assert(res == Sqlite.OK);
            res = stmt.bind_text (5, avatar);
            assert(res == Sqlite.OK);
            res = stmt.bind_text (6, service);
            assert(res == Sqlite.OK);

            res = stmt.step ();

            if (res == Sqlite.DONE)
                debug ("account added: " + service);
        }

        public void add_user (string? screen_name = null, string? name = null,
                int account_id) {

            Sqlite.Statement stmt;

            reset_default_account ();

            int res = db.prepare_v2("INSERT INTO users (screen_name, " +
                "name, account_id) " +
                "VALUES (?, ?, ?)", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (1, screen_name);
            assert(res == Sqlite.OK);
            res = stmt.bind_text (2, name);
            assert(res == Sqlite.OK);
            res = stmt.bind_int (3, account_id);
            assert(res == Sqlite.OK);

            res = stmt.step ();

            if (res == Sqlite.DONE)
                debug ("user added: " + screen_name);
        }

        public void reset_default_account () {
            Sqlite.Statement stmt;
            int res = db.prepare_v2 ("UPDATE accounts SET default_account = ? " +
                "WHERE default_account = ?", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, 0);
            assert(res == Sqlite.OK);
            res = stmt.bind_int (2, 1);
            assert (res == Sqlite.OK);

            res = stmt.step ();
            if (res != Sqlite.DONE) {
                debug ("default account not reset");
            }
        }

        public void set_default_account (User account) {

            Sqlite.Statement stmt;

            reset_default_account ();

            int res = db.prepare_v2 ("UPDATE accounts SET default_account = ? " +
                "WHERE token = ?", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, 1);
            debug ("1");
            assert (res == Sqlite.OK);
            res = stmt.bind_text (2, account.token);
            debug ("2");
            assert (res == Sqlite.OK);

            res = stmt.step ();
        }

        public void update_account (User account) {
            Sqlite.Statement stmt;
            int res = db.prepare_v2 ("UPDATE accounts SET screen_name = ?, " +
                "name = ?, avatar = ? WHERE token = ?", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_text (1, account.screen_name);
            assert (res == Sqlite.OK);
            res = stmt.bind_text (2, account.name);
            assert (res == Sqlite.OK);
            res = stmt.bind_text (3, account.profile_image_file);
            assert (res == Sqlite.OK);
            res = stmt.bind_text (4, account.token);
            assert (res == Sqlite.OK);

            res = stmt.step ();
        }

        // get

        public int? get_account_id () {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT id FROM accounts WHERE default_account = 1 LIMIT 1",
                -1, out stmt);
            assert (res == Sqlite.OK);

            if (stmt.step() != Sqlite.ROW)
                return null;

            return stmt.column_int (0);
        }

        public User? get_default_account () {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT * FROM accounts WHERE default_account = 1 LIMIT 1",
                -1, out stmt);
            assert (res == Sqlite.OK);

            if (stmt.step() != Sqlite.ROW) {
                res = db.prepare_v2 ("SELECT * FROM accounts LIMIT 1",
                    -1, out stmt);
                assert (res == Sqlite.OK);

                if (stmt.step() != Sqlite.ROW)
                    return null;
            }

            User account = new User ();
            account.screen_name = stmt.column_text (1);
            account.name = stmt.column_text (2);
            account.token = stmt.column_text (3);
            account.token_secret = stmt.column_text (4);
            account.profile_image_file = stmt.column_text (5);
            account.service = stmt.column_text (6);
            return account;
        }

        public User? get_account (string screen_name, string service) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT * FROM accounts WHERE screen_name = ? AND service = ? LIMIT 1",
                -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_text (1, screen_name);
            assert (res == Sqlite.OK);
            res = stmt.bind_text (2, service);
            assert (res == Sqlite.OK);

            if (stmt.step() != Sqlite.ROW)
                return null;

            User account = new User ();
            account.screen_name = stmt.column_text (1);
            account.name = stmt.column_text (2);
            account.token = stmt.column_text (3);
            account.token_secret = stmt.column_text (4);
            account.profile_image_file = stmt.column_text (5);
            account.service = stmt.column_text (6);
            return account;
        }

        public List<User?> get_all_accounts () {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT * FROM accounts ORDER BY default_account",
                -1, out stmt);
            assert (res == Sqlite.OK);

            List<User?> all = new List<User?> ();

        while ((res = stmt.step()) == Sqlite.ROW) {
            User account = new User ();
            account.screen_name = stmt.column_text (1);
            account.name = stmt.column_text (2);
            account.token = stmt.column_text (3);
            account.token_secret = stmt.column_text (4);
            account.profile_image_file = stmt.column_text (5);
            account.service = stmt.column_text (6);
            all.append (account);
        }
        return all;
        }

        // callbacks
    }
}
