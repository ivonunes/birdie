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
    public class Twitter : API {
        public Twitter () {
            this.CONSUMER_KEY = "T1VkU2dySk9DRFlZbjJJcDdWSGZRdw==";
            this.CONSUMER_SECRET = "UHZPdXcwWFJoVnJ5RU5yZXdGdDZWd1lGdnNoRlpwcHQxMUtkNDdvVWM=";
            this.URL_FORMAT = "https://api.twitter.com";
            this.REQUEST_TOKEN_URL = "https://api.twitter.com/oauth/request_token";
            this.FUNCTION_ACCESS_TOKEN = "oauth/access_token";

            this.CONSUMER_KEY = (string) Base64.decode (this.CONSUMER_KEY);
            this.CONSUMER_SECRET = (string) Base64.decode (this.CONSUMER_SECRET);

            this.proxy = new Rest.OAuthProxy (CONSUMER_KEY, CONSUMER_SECRET, URL_FORMAT, false);

            this.settings = new Settings ("org.pantheon.birdie");

            this.token = settings.get_string ("token");
            this.token_secret = settings.get_string ("token-secret");
        }

        public override string get_request () {
            // request token
            try {
                proxy.request_token ("oauth/request_token", "oob");
            } catch (Error e) {
                stderr.printf ("Couldn't get request token: %s\n", e.message);
                return "http://dl.dropbox.com/u/10382236/twitter.html";
            }

            return "http://twitter.com/oauth/authorize?oauth_token=" + proxy.get_token ();
        }

        public override int get_tokens (string pin) {
            // access token
            try {
                proxy.access_token (FUNCTION_ACCESS_TOKEN, pin);
                token = proxy.get_token();
                token_secret = proxy.get_token_secret();

                settings.set_string ("token", token);
                settings.set_string ("token-secret", token_secret);
            } catch (Error e) {
                stderr.printf ("Couldn't get access token: %s\n", e.message);
                return 1;
            }

            return 0;
        }

        public override int auth () {
            home_timeline = new GLib.List<Tweet> ();

            if (token == "" || token_secret == "") {
                return 1;
            } else {
                proxy.set_token(token);
                proxy.set_token_secret(token_secret);
            }

            this.since_id_home = "";
            this.since_id_mentions = "";
            this.since_id_dm = "";

            return 0;
        }

        public override int64 update (string status, string id = "") {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/update.json");
            call.set_method ("POST");
            call.add_param ("status", status);
            if (id != "")
                call.add_param ("in_reply_to_status_id", id);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();
                var userobject = root.get_object ();

                var user_id = userobject.get_int_member ("id");

			    return user_id;
            } catch (Error e) {
                stderr.printf ("Unable to parse update.json\n");
            }

            return 0;
        }

        public override int destroy (string id) {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/destroy/" + id + ".json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            return 0;
        }

        public override int retweet (string id) {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/retweet/" + id + ".json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                if (e.message == "Forbidden")
                    return 0;
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            return 0;
        }

        public override int favorite_create (string id) {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/favorites/create.json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            return 0;
        }

        public override int favorite_destroy (string id) {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/favorites/destroy.json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            return 0;
        }

        public override int send_direct_message (string recipient, string status) {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/direct_messages/new.json");
            call.set_method ("POST");
            call.add_param ("screen_name", recipient);
            call.add_param ("text", status);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            return 0;
        }

        public override int get_account () {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/account/verify_credentials.json");
            call.set_method ("GET");

            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                var desc = "";
                var location = "";

                parser.load_from_data ((string) call.get_payload (), -1);
                var root = parser.get_root ();
                var userobject = root.get_object ();

                var id = userobject.get_string_member ("id_str");
			    var name = userobject.get_string_member ("name");
			    var screen_name = userobject.get_string_member ("screen_name");
			    var profile_image_url = userobject.get_string_member ("profile_image_url");
			    var profile_image_file = get_avatar (profile_image_url);

                if (userobject.has_member("location") &&
			        userobject.get_string_member ("location") != null) {
                     location = userobject.get_string_member ("location");
                }


			    if (userobject.has_member("description") &&
			        userobject.get_string_member ("description") != null) {
                     desc = userobject.get_string_member ("description");
                }

                int64 friends_count = userobject.get_int_member ("friends_count");
                int64 followers_count = userobject.get_int_member ("followers_count");
                int64 statuses_count = userobject.get_int_member ("statuses_count");

                account = new User (id, name, screen_name,
                    profile_image_url, profile_image_file, location, desc,
                    friends_count, followers_count, statuses_count
                );

            } catch (Error e) {
                stderr.printf ("Unable to parse verify_credentials.json\n");
            }

            return 0;
        }
        
        public void get_user (Json.Node tweetnode) {
            var tweetobject = tweetnode.get_object();

            var id = tweetobject.get_object_member ("user").get_string_member ("id_str");
            var name = tweetobject.get_object_member ("user").get_string_member ("name");
			var screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
			var profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
		    var profile_image_file = get_avatar (profile_image_url);
		    
		    string location = "";
		    string description = "";
		    
		    if (tweetobject.get_object_member ("user").has_member("location") &&
			     tweetobject.get_object_member ("user").get_string_member ("location") != null) {
                location = tweetobject.get_object_member ("user").get_string_member ("location");
            }
            
            if (tweetobject.get_object_member ("user").has_member("description") &&
			     tweetobject.get_object_member ("user").get_string_member ("description") != null) {
                description = tweetobject.get_object_member ("user").get_string_member ("description");
            }
            
            int64 friends_count = tweetobject.get_object_member ("user").get_int_member ("friends_count");
            int64 followers_count = tweetobject.get_object_member ("user").get_int_member ("followers_count");
            int64 statuses_count = tweetobject.get_object_member ("user").get_int_member ("statuses_count");
			        
			this.user = new User (id, name, screen_name,
                profile_image_url, profile_image_file, location, description,
                friends_count, followers_count, statuses_count
            );
        }

        public override string get_avatar (string profile_image_url) {
            var profile_image_file = profile_image_url;

            bool convert_png = false;

            Gdk.Pixbuf pixbuf = null;

            if ("/" in profile_image_file)
                profile_image_file = profile_image_file.split ("/")[4] + "_" + profile_image_file.split ("/")[5];

            if (".png" in profile_image_url) {
                convert_png = false;
            } else {
                if ("." in profile_image_file) {
                    profile_image_file = profile_image_file.split (".")[0];
                }
                profile_image_file = profile_image_file + ".png";
                convert_png = true;
            }

            var file = File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file);

            if (!file.query_exists ()) {
                GLib.DirUtils.create_with_parents(Environment.get_home_dir () + "/.cache/birdie", 0775);

                var src = File.new_for_uri (profile_image_url);
                var dst = File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file);
                try {
                    src.copy (dst, FileCopyFlags.NONE, null, null);
                } catch (Error e) {
                    stderr.printf ("%s\n", e.message);
                }

                // generate rounded avatar
                var surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 50, 50);
                var ctx = new Cairo.Context (surface);

                Utils.draw_rounded_path(ctx, 0, 0, 50, 50, 5);
                ctx.set_line_width (2.0);
                ctx.set_source_rgb (0.5, 0.5, 0.5);
                ctx.stroke_preserve ();

                try {
                    pixbuf = new Gdk.Pixbuf.from_file (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file);
                } catch (Error e) {
                    warning ("Pixbuf error: %s", e.message);
                }

                if(pixbuf != null) {
                    Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 1, 1);
                    ctx.clip ();
                }

                ctx.paint ();

                surface.write_to_png (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file);
            }

            return profile_image_file;
        }

        public override string highligh_links (owned string text) {
            if ("\n" in text)
                text = text.replace ("\n", " ");

            try {
                urls = new Regex("((http|https|ftp)://(([[:alpha:]0-9_]|[/.]|[~])*)\\b)");
                text = urls.replace(text, -1, 0, "<span underline='none'><a href='\\0'>\\0</a></span>");
                urls = new Regex("([#][[:alpha:]0-9_]+)");
                text = urls.replace(text, -1, 0, "<span underline='none'><a href='https://twitter.com/\\0'>\\0</a></span>");
                urls = new Regex("([@][[:alpha:]0-9_]+)");
                text = urls.replace(text, -1, 0, "<span underline='none'><a href='birdie://user/\\0'>\\0</a></span>");
            } catch (RegexError e) {
                warning ("regex error: %s", e.message);
            }

            return text;
        }

        public override Tweet get_tweet (Json.Node tweetnode) {
            var tweetobject = tweetnode.get_object();

            var actual_id = tweetobject.get_string_member ("id_str");
            var retweet = tweetobject.get_member ("retweeted_status");
            string retweeted_by = "";

            if (retweet != null) {
                retweeted_by = tweetobject.get_object_member ("user").get_string_member ("screen_name");
                tweetobject = tweetobject.get_object_member ("retweeted_status");
            }

            var id = tweetobject.get_string_member ("id_str");
            var retweeted = tweetobject.get_boolean_member ("retweeted");
			var favorited = tweetobject.get_boolean_member ("favorited");
			var user_name = tweetobject.get_object_member ("user").get_string_member ("name");
			var user_screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
			var text = highligh_links(tweetobject.get_string_member ("text"));
			var created_at = tweetobject.get_string_member ("created_at");
			var profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");

			var profile_image_file = get_avatar (profile_image_url);
			var in_reply_to_screen_name = tweetobject.get_string_member ("in_reply_to_screen_name");

			if (in_reply_to_screen_name == null) {
			    in_reply_to_screen_name = "";
			}

			return new Tweet (id, actual_id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, retweeted, favorited, false, in_reply_to_screen_name, retweeted_by);
        }

        public override int get_home_timeline (string count = "20") {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/home_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            if (this.since_id_home != "")
                call.add_param ("since_id", this.since_id_home);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                // clear since_id list
                this.home_timeline_since_id.foreach ((tweet) => {
                    this.home_timeline_since_id.remove(tweet);
	            });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode);
			        home_timeline_since_id.append (tweet);
                }

                this.home_timeline_since_id.reverse ();
                this.home_timeline_since_id.foreach ((tweet) => {
                    this.home_timeline.append(tweet);
                    this.since_id_home = tweet.actual_id;
	            });

            } catch (Error e) {
                stderr.printf ("Unable to parse home_timeline.json\n");
            }

            return 0;
        }

        public override int get_mentions_timeline (string count = "20") {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/mentions_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            if (this.since_id_mentions != "")
                call.add_param ("since_id", this.since_id_mentions);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                // clear since_id list
                this.mentions_timeline_since_id.foreach ((tweet) => {
                    this.mentions_timeline_since_id.remove(tweet);
	            });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode);
			        mentions_timeline_since_id.append (tweet);
                }

                this.mentions_timeline_since_id.reverse ();
                this.mentions_timeline_since_id.foreach ((tweet) => {
                    this.mentions_timeline.append(tweet);
                    this.since_id_mentions = tweet.actual_id;
	            });

            } catch (Error e) {
                stderr.printf ("Unable to parse mentions_timeline.json\n");
            }

            return 0;
        }

        public override int get_direct_messages (string count = "20") {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/direct_messages.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            if (this.since_id_dm != "")
                call.add_param ("since_id", this.since_id_dm);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                // clear since_id list
                this.dm_timeline_since_id.foreach ((tweet) => {
                    this.dm_timeline_since_id.remove(tweet);
	            });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweetobject = tweetnode.get_object();

                    var id = tweetobject.get_string_member ("id_str");
			        var user_name = tweetobject.get_object_member ("sender").get_string_member ("name");
			        var user_screen_name = tweetobject.get_object_member ("sender").get_string_member ("screen_name");
			        var text = highligh_links(tweetobject.get_string_member ("text"));
			        var created_at = tweetobject.get_string_member ("created_at");
			        var profile_image_url = tweetobject.get_object_member ("sender").get_string_member ("profile_image_url");
			        var profile_image_file = get_avatar (profile_image_url);

			        var tweet = new Tweet (id, id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, false, false, true);

			        dm_timeline_since_id.append (tweet);
                }

                this.dm_timeline_since_id.reverse ();
                this.dm_timeline_since_id.foreach ((tweet) => {
                    this.dm_timeline.append(tweet);
                    this.since_id_dm = tweet.actual_id;
	            });

            } catch (Error e) {
                stderr.printf ("Unable to parse direct_messages.json\n");
            }

            return 0;
        }

        public override int get_direct_messages_sent (string count = "20") {
            // setup call
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/direct_messages/sent.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweetobject = tweetnode.get_object();

                    var id = tweetobject.get_string_member ("id_str");
			        var user_name = tweetobject.get_object_member ("sender").get_string_member ("name");
			        var user_screen_name = tweetobject.get_object_member ("recipient").get_string_member ("screen_name");
			        var text = highligh_links(tweetobject.get_string_member ("text"));
			        var created_at = tweetobject.get_string_member ("created_at");
			        var profile_image_url = tweetobject.get_object_member ("sender").get_string_member ("profile_image_url");
			        var profile_image_file = get_avatar (profile_image_url);

			        var tweet = new Tweet (id, id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, false, false, true);

			        dm_sent_timeline.append (tweet);
                }

                this.dm_sent_timeline.reverse ();

            } catch (Error e) {
                stderr.printf ("Unable to parse sent.json\n");
            }

            return 0;
        }

        public override int get_own_timeline (string count = "20") {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/user_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            call.add_param ("user_id", this.account.id);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode);

                    if (tweet.retweeted_by != "") {
                        tweet.retweeted = true;
                    }

			        own_timeline.append (tweet);
                }

                own_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }
            return 0;
        }

        public override int get_favorites (string count = "20") {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/favorites/list.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            call.add_param ("user_id", this.account.id);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode);

                    if (tweet.retweeted_by != "") {
                        tweet.retweeted = true;
                    }

			        favorites.append (tweet);
                }

                favorites.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse favorites.json\n");
            }
            return 0;
        }
        
        public override Array<string> get_friendship (string source_user, string target_user) {
            Array<string> friendship = new Array<string> ();
            
            bool following = false;
            bool blocking = false;
            bool followed = false;
            
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/friendships/show.json");
            call.set_method ("GET");
            call.add_param ("source_screen_name", source_user);
            call.add_param ("target_screen_name", target_user);

            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
            }

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);
                var root = parser.get_root ();
                var userobject = root.get_object ();
                var usermember = userobject.get_object_member ("relationship");
                
                following = usermember.get_object_member ("source").get_boolean_member ("following");
                blocking = usermember.get_object_member ("source").get_boolean_member ("blocking");
                followed = usermember.get_object_member ("source").get_boolean_member ("followed_by");
                  
            } catch (Error e) {
                stderr.printf ("Unable to parse sent.json\n");
            }
            
            friendship.append_val (following.to_string ());
            friendship.append_val (blocking.to_string ());      
            friendship.append_val (followed.to_string ());
            
            return friendship;
        }
        
        public override int create_friendship (string screen_name) {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/friendships/create.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }
            return 0;
        }
        
        public override int destroy_friendship (string screen_name) {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/friendships/destroy.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }
            return 0;
        }
        
        public override int create_block (string screen_name) {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/blocks/create.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }
            return 0;
        }
        
        public override int destroy_block (string screen_name) {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/blocks/destroy.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }
            return 0;
        }

        public override int get_user_timeline (string screen_name, string count = "20") {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/user_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }

            this.user_timeline.foreach ((tweet) => {
                this.user_timeline.remove (tweet);
	        });

            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode);
			        user_timeline.append (tweet);
			        this.get_user (tweetnode);
                }

                user_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }

            return 0;
        }
    }
}
