// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2016 Birdie Developers (http://birdieapp.github.io)
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivoavnunes@gmail.com>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie {

    public class SqliteDatabase : GLib.Object {

        private Sqlite.Database db;
        private string db_path;

        public SqliteDatabase (bool skip_tables = false) {
            int rc = 0;

            this.db_path = Environment.get_home_dir () + "/.local/share/birdie/birdie.db";

            if (!skip_tables) {
                if (create_tables () != Sqlite.OK) {
                    stderr.printf ("Error creating db table: %d, %s\n", rc, this.db.errmsg ());
                    Gtk.main_quit ();
                }
            }

            rc = Sqlite.Database.open (this.db_path, out this.db);

            if (rc != Sqlite.OK) {
                stderr.printf ("Can't open database: %d, %s\n", rc, this.db.errmsg ());
                Gtk.main_quit ();
            }
        }

        // create tables

        private int create_tables () {
            int rc;
            rc = Sqlite.Database.open (this.db_path, out this.db);

            if (rc != Sqlite.OK) {
                stderr.printf ("Can't open database: %d, %s\n", rc, this.db.errmsg ());
                Gtk.main_quit ();
            }

            // accounts table
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                 "screen_name VARCHAR, name VARCHAR," +
                 "token VARCHAR, token_secret VARCHAR," +
                 "avatar VARCHAR, service VARCHAR," +
                 "default_account INTEGER)", null, null);

            debug ("Table accounts created");

            // cached home timeline
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS tweets (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "tweet_id VARCHAR, actual_id VARCHAR, user_name VARCHAR, user_screen_name VARCHAR," +
                "text VARCHAR, created_at VARCHAR, profile_image_url VARCHAR, profile_image_file VARCHAR," +
                "retweeted INTEGER, favorited INTEGER, dm INTEGER, in_reply_to_screen_name VARCHAR," +
                "retweeted_by VARCHAR, retweeted_by_name VARCHAR, media_url VARCHAR, youtube_video VARCHAR," +
                "verified INTEGER, account_id INTEGER)", null, null);

            // this is needed for 0.2.1 -> 0.3 upgrade
            if (!this.has_column ("tweets", "account_id")) {
                debug ("upgrading from birdie 0.2.1");
                rc = this.db.exec ("ALTER TABLE tweets ADD COLUMN account_id INTEGER", null, null);
            }
            //

            debug ("Table tweets created");

            // cached mentions timeline
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS mentions (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "tweet_id VARCHAR, actual_id VARCHAR, user_name VARCHAR, user_screen_name VARCHAR," +
                "text VARCHAR, created_at VARCHAR, profile_image_url VARCHAR, profile_image_file VARCHAR," +
                "retweeted INTEGER, favorited INTEGER, dm INTEGER, in_reply_to_screen_name VARCHAR," +
                "retweeted_by VARCHAR, retweeted_by_name VARCHAR, media_url VARCHAR, youtube_video VARCHAR," +
                "verified INTEGER, account_id INTEGER)", null, null);

            debug ("Table mentions created");

            // cached dm inbox timeline
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS dm_inbox (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "tweet_id VARCHAR, actual_id VARCHAR, user_name VARCHAR, user_screen_name VARCHAR," +
                "text VARCHAR, created_at VARCHAR, profile_image_url VARCHAR, profile_image_file VARCHAR," +
                "retweeted INTEGER, favorited INTEGER, dm INTEGER, in_reply_to_screen_name VARCHAR," +
                "retweeted_by VARCHAR, retweeted_by_name VARCHAR, media_url VARCHAR, youtube_video VARCHAR," +
                "verified INTEGER, account_id INTEGER)", null, null);

            debug ("Table dm_inbox created");

            // cached dm outbox timeline
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS dm_outbox (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "tweet_id VARCHAR, actual_id VARCHAR, user_name VARCHAR, user_screen_name VARCHAR," +
                "text VARCHAR, created_at VARCHAR, profile_image_url VARCHAR, profile_image_file VARCHAR," +
                "retweeted INTEGER, favorited INTEGER, dm INTEGER, in_reply_to_screen_name VARCHAR," +
                "retweeted_by VARCHAR, retweeted_by_name VARCHAR, media_url VARCHAR, youtube_video VARCHAR," +
                "verified INTEGER, account_id INTEGER)", null, null);

            debug ("Table dm_outbox created");

            // cached own timeline
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS own (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "tweet_id VARCHAR, actual_id VARCHAR, user_name VARCHAR, user_screen_name VARCHAR," +
                "text VARCHAR, created_at VARCHAR, profile_image_url VARCHAR, profile_image_file VARCHAR," +
                "retweeted INTEGER, favorited INTEGER, dm INTEGER, in_reply_to_screen_name VARCHAR," +
                "retweeted_by VARCHAR, retweeted_by_name VARCHAR, media_url VARCHAR, youtube_video VARCHAR," +
                "verified INTEGER, account_id INTEGER)", null, null);

            debug ("Table own created");

            // cached favorites timeline
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS favorites (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                "tweet_id VARCHAR, actual_id VARCHAR, user_name VARCHAR, user_screen_name VARCHAR," +
                "text VARCHAR, created_at VARCHAR, profile_image_url VARCHAR, profile_image_file VARCHAR," +
                "retweeted INTEGER, favorited INTEGER, dm INTEGER, in_reply_to_screen_name VARCHAR," +
                "retweeted_by VARCHAR, retweeted_by_name VARCHAR, media_url VARCHAR, youtube_video VARCHAR," +
                "verified INTEGER, account_id INTEGER)", null, null);

            debug ("Table favorites created");

            // user completion table
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                 "screen_name VARCHAR, name VARCHAR," +
                 "account_id INTEGER)", null, null);

            debug ("Table users created");

            // hashtags completion table
            rc = this.db.exec ("CREATE TABLE IF NOT EXISTS hashtags (id INTEGER PRIMARY KEY AUTOINCREMENT," +
                 "hashtag VARCHAR," +
                 "account_id INTEGER)", null, null);

            debug ("Table hashtags created");

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

            int res = db.prepare_v2 ("INSERT INTO accounts (screen_name, " +
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

        public async void add_user (string screen_name, string name,
                int account_id) {
            new Thread<void*> (null, () => {
                Sqlite.Statement stmt;

                if (!user_exists ("@" + screen_name, account_id)) {

                    int res = db.prepare_v2 ("INSERT INTO users (screen_name, " +
                        "name, account_id) " +
                        "VALUES (?, ?, ?)", -1, out stmt);
                    assert(res == Sqlite.OK);

                    res = stmt.bind_text (1, "@" + screen_name);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (2, name);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (3, account_id);
                    assert(res == Sqlite.OK);

                    res = stmt.step ();

                    if (res == Sqlite.DONE)
                        debug ("user added: " + screen_name);
                }

                return null;
            });
        }

        public async void add_hashtag (string hashtag, int account_id) {
            new Thread<void*> (null, () => {
                Sqlite.Statement stmt;

                if (!hashtag_exists ("#" + hashtag, account_id)) {

                    int res = db.prepare_v2 ("INSERT INTO hashtags (hashtag, account_id) " +
                        "VALUES (?, ?)", -1, out stmt);
                    assert(res == Sqlite.OK);

                    res = stmt.bind_text (1, "#" + hashtag);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (2, account_id);
                    assert(res == Sqlite.OK);

                    res = stmt.step ();

                    if (res == Sqlite.DONE)
                        debug ("hashtag added: " + hashtag);
                }

                return null;
            });
        }

        public async void add_tweet (Tweet tweet, string table, int account_id) {
            new Thread<void*> (null, () => {
                Sqlite.Statement stmt;

                if (!tweet_exists (tweet.id, account_id, table)) {

                    int res = db.prepare_v2("INSERT INTO " + table + " (tweet_id, " +
                        "actual_id, user_name, user_screen_name, text, created_at, " +
                        "profile_image_url, profile_image_file, retweeted, favorited, dm, " +
                        "in_reply_to_screen_name, retweeted_by, retweeted_by_name, media_url, " +
                        "youtube_video, verified, account_id) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", -1, out stmt);
                    assert(res == Sqlite.OK);

                    res = stmt.bind_text (1, tweet.id);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (2, tweet.actual_id);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (3, tweet.user_name);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (4, tweet.user_screen_name);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (5, tweet.text);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (6, tweet.created_at);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (7, tweet.profile_image_url);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (8, tweet.profile_image_file);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (9, tweet.retweeted ? 1 : 0);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (10, tweet.favorited ? 1 : 0);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (11, tweet.dm ? 1 : 0);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (12, tweet.in_reply_to_screen_name);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (13, tweet.retweeted_by);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (14, tweet.retweeted_by_name);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (15, tweet.media_url);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_text (16, tweet.youtube_video);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (17, tweet.verified ? 1 : 0);
                    assert(res == Sqlite.OK);
                    res = stmt.bind_int (18, account_id);
                    assert(res == Sqlite.OK);

                    res = stmt.step ();

                    if (res == Sqlite.DONE)
                        debug ("tweet added to cache: " + tweet.actual_id);
                }

                return null;
            });
        }

        public bool user_exists (string screen_name, int account_id) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT id FROM users " +
                "WHERE screen_name LIKE ? AND account_id = ?", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (1, screen_name);
            assert(res == Sqlite.OK);
            res = stmt.bind_int (2, account_id);
            assert(res == Sqlite.OK);

            if (stmt.step() == Sqlite.ROW) {
                return true;
            } else {
                return false;
            }
        }

        public bool tweet_exists (string tweet_id, int account_id, string table) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT tweet_id FROM " + table +
                " WHERE tweet_id LIKE ? AND account_id = ?", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (1, tweet_id);
            assert(res == Sqlite.OK);
            res = stmt.bind_int (2, account_id);
            assert(res == Sqlite.OK);

            if (stmt.step() == Sqlite.ROW) {
                return true;
            } else {
                return false;
            }
        }

        public bool hashtag_exists (string hashtag, int account_id) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT id FROM hashtags " +
                "WHERE hashtag LIKE ? AND account_id = ?", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (1, hashtag);
            assert(res == Sqlite.OK);
            res = stmt.bind_int (2, account_id);
            assert(res == Sqlite.OK);

            if (stmt.step() == Sqlite.ROW) {
                return true;
            } else {
                return false;
            }
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

        public void set_favorite (string id, int account_id, int state, string table) {
            Sqlite.Statement stmt;
            int res = db.prepare_v2 ("UPDATE " + table + " SET favorited = ? " +
                "WHERE account_id = ? AND actual_id = ?", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, state);
            assert (res == Sqlite.OK);
            res = stmt.bind_int (2, account_id);
            assert (res == Sqlite.OK);
            res = stmt.bind_text (3, id);
            assert (res == Sqlite.OK);

            res = stmt.step ();
            if (res != Sqlite.DONE) {
                debug ("error setting favorite flag");
            }
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

        public List<string?> get_users (int account_id) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT screen_name FROM users WHERE account_id = ?" +
                " ORDER BY screen_name", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, account_id);
            assert (res == Sqlite.OK);

            List<string?> all = new List<string?> ();

            while ((res = stmt.step()) == Sqlite.ROW) {
                all.append (stmt.column_text(0));
            }
            return all;
        }

        public List<string?> get_hashtags (int account_id) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT hashtag FROM hashtags WHERE account_id = ?" +
                " ORDER BY hashtag", -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, account_id);
            assert (res == Sqlite.OK);

            List<string?> all = new List<string?> ();

            while ((res = stmt.step()) == Sqlite.ROW) {
                all.append (stmt.column_text(0));
            }
            return all;
        }

        public List<Tweet?> get_tweets (string table, int account_id) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT * FROM " + table +
                " WHERE account_id = ? ORDER BY tweet_id DESC LIMIT 20",
                -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int (1, account_id);
            assert (res == Sqlite.OK);

            List<Tweet?> all = new List<Tweet?> ();

            while ((res = stmt.step()) == Sqlite.ROW) {
                Tweet tweet = new Tweet ();
                tweet.id = stmt.column_text (1);
                tweet.actual_id = stmt.column_text (2);
                tweet.user_name = stmt.column_text (3);
                tweet.user_screen_name = stmt.column_text (4);
                tweet.text = stmt.column_text (5);
                tweet.created_at = stmt.column_text (6);
                tweet.profile_image_url = stmt.column_text (7);
                tweet.profile_image_file = stmt.column_text (8);
                if (stmt.column_int (9) == 1) {
                    tweet.retweeted = true;
                } else {
                    tweet.retweeted = false;
                }
                if (stmt.column_int (10) == 1) {
                    tweet.favorited = true;
                } else {
                    tweet.favorited = false;
                }
                if (stmt.column_int (11) == 1) {
                    tweet.dm = true;
                } else {
                    tweet.dm = false;
                }
                tweet.in_reply_to_screen_name = stmt.column_text (12);
                tweet.retweeted_by = stmt.column_text (13);
                tweet.retweeted_by_name = stmt.column_text (14);
                tweet.media_url = stmt.column_text (15);
                tweet.youtube_video = stmt.column_text (16);
                if (stmt.column_int (17) == 1) {
                    tweet.verified = true;
                } else {
                    tweet.verified = false;
                }

                all.append (tweet);
            }

            all.reverse ();
            return all;
        }

        public string? get_since_id (string table, int account_id) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT actual_id FROM " + table +
                " WHERE account_id = ? ORDER BY actual_id DESC LIMIT 1",
                -1, out stmt);
            res = stmt.bind_int (1, account_id);
            assert (res == Sqlite.OK);

            if (stmt.step() != Sqlite.ROW)
                return null;

            return stmt.column_text (0);
        }

        public int get_row_count (string table) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("SELECT COUNT(id) AS RowCount FROM " + table, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.step ();
            if (res != Sqlite.ROW) {
                critical ("Unable to retrieve row count on %s: (%d) %s", table, res, db.errmsg());
                return 0;
            }
            return stmt.column_int (0);
        }

        // delete

        public void remove_account (User account) {
            Sqlite.Statement stmt;

            reset_default_account ();

            int res = db.prepare_v2 ("DELETE FROM accounts WHERE token = " +
                "?", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (1, account.token);
            assert(res == Sqlite.OK);

            res = stmt.step ();

            if (res == Sqlite.DONE)
                debug ("user removed: " + account.screen_name);
        }

        public void remove_status (string id, int account_id, string table) {
            Sqlite.Statement stmt;

            int res = db.prepare_v2 ("DELETE FROM " + table + " WHERE account_id = ? AND actual_id = ?", -1, out stmt);
            assert(res == Sqlite.OK);

            res = stmt.bind_int (1, account_id);
            assert(res == Sqlite.OK);

            res = stmt.bind_text (2, id);
            assert(res == Sqlite.OK);

            res = stmt.step ();

            if (res == Sqlite.DONE)
                debug ("status removed: " + id);
        }

        public void purge_tweets (string table) {
            Sqlite.Statement stmt;
            int res;
            int rows = get_row_count (table);
            if (rows > 100) {
                res = db.prepare_v2 ("DELETE FROM " + table +
                " WHERE id IN (SELECT id FROM " + table +
                " ORDER BY id LIMIT " + (rows - 100).to_string () + ")", -1, out stmt);
                assert (res == Sqlite.OK);

                res = stmt.step ();
            }
        }

        public bool has_column (string table_name, string column_name) {
            Sqlite.Statement stmt;
            int res = db.prepare_v2 ("PRAGMA table_info(%s)".printf (table_name), -1, out stmt);
            assert (res == Sqlite.OK);

            for (;;) {
                res = stmt.step ();
                if (res == Sqlite.DONE) {
                    break;
                } else if (res != Sqlite.ROW) {
                    break;
                } else {
                    string column = stmt.column_text (1);
                    if (column != null && column == column_name)
                        return true;
                }
            }
            return false;
        }
    }
}
