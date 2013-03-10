namespace Birdie {
    public class Twitter {
        private static const string CONSUMER_KEY = "zVamkAeSRTL349AgSjIMIQ";
        private static const string CONSUMER_SECRET = "5aaldQWP4KQhv8dRkWsjYeLcbSkE3K8uv96A8yGjI";
        private static const string URL_FORMAT = "https://api.twitter.com";
        private static const string REQUEST_TOKEN_URL = "https://api.twitter.com/oauth/request_token";
        private static const string FUNCTION_ACCESS_TOKEN = "oauth/access_token";

        private Rest.OAuthProxy proxy;
        
        private string since_id_home;
        private string since_id_mentions;
        private bool first_run_home;
        private bool first_run_mentions;
        
        public User account;
        public GLib.List<Tweet> home_timeline;
        public GLib.List<Tweet> home_timeline_since_id;
        public GLib.List<Tweet> mentions_timeline;
        public GLib.List<Tweet> mentions_timeline_since_id;
        public GLib.List<Tweet> own_timeline;
        public GLib.List<Tweet> user_timeline;

        public int auth () {
            var settings = new Settings ("org.pantheon.birdie");
            
            var token = settings.get_string ("token");
            var token_secret = settings.get_string ("token-secret");

            home_timeline = new GLib.List<Tweet> ();
            proxy = new Rest.OAuthProxy (CONSUMER_KEY, CONSUMER_SECRET, URL_FORMAT, false);

            if (token == "" || token_secret == "") {
                // request token
                try {
                    proxy.request_token ("oauth/request_token", "oob");
                } catch (Error e) {
                    stderr.printf ("Couldn't get request token: %s\n", e.message);
                    return 1;
                }

                // prompt user for pin
                stdout.printf ("Go to http://twitter.com/oauth/authorize?oauth_token=%s then enter the PIN\n", proxy.get_token ());
                string pin = stdin.read_line ();

                // access token
                try { 
                    proxy.access_token (FUNCTION_ACCESS_TOKEN, pin);
                    token = proxy.get_token();
                    token_secret = proxy.get_token_secret();
                    
                    settings.set_string ("token", token);
                    settings.set_string ("token-secret", token_secret);
                }
                catch (Error e) {
                    stderr.printf ("Couldn't get access token: %s\n", e.message);
                    return 1;
                }
            } else {
                proxy.set_token(token);
                proxy.set_token_secret(token_secret);
            }
            
            this.since_id_home = "";
            this.since_id_mentions = "";
            
            this.first_run_home = true;
            this.first_run_mentions = true;
            
            return 0;
        }

        public int64 update (string status, string id = "") {
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
        
        public int destroy (string id) {
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
        
        public int retweet (string id) {
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
        
        public int get_account () {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/account/verify_credentials.json");
            call.set_method ("GET");
            
            try { call.sync (); } catch (Error e) {
                stderr.printf ("Cannot make call: %s\n", e.message);
                return 1;
            }
            
            try {
                var parser = new Json.Parser ();
                parser.load_from_data ((string) call.get_payload (), -1);

                var root = parser.get_root ();
                var userobject = root.get_object ();
                    
                var id = userobject.get_string_member ("id_str");
			    var name = userobject.get_string_member ("name");
			    var screen_name = userobject.get_string_member ("screen_name");
			    var profile_image_url = userobject.get_string_member ("profile_image_url");
			       
			    var profile_image_file = get_avatar (profile_image_url);
                    
                account = new User (id, name, screen_name, profile_image_url, profile_image_file);
            } catch (Error e) {
                stderr.printf ("Unable to parse verify_credentials.json\n");
            }

            return 0;
        }
        
        public string get_avatar (string profile_image_url) {
            var profile_image_file = profile_image_url;
            
            bool convert_png = false;
                        
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
                        
                Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file);
                if(pixbuf != null) {
                    Gdk.cairo_set_source_pixbuf(ctx, pixbuf, 1, 1);
                    ctx.clip ();
                }
                        
                ctx.paint ();

                surface.write_to_png (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file);
            }
            
            return profile_image_file;
        }
        
        public int get_home_timeline (string count = "20") {
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
                    var tweetobject = tweetnode.get_object();
                    
                    var id = tweetobject.get_string_member ("id_str");
			        var user_name = tweetobject.get_object_member ("user").get_string_member ("name");
			        var user_screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
			        var text = tweetobject.get_string_member ("text");
			        var created_at = tweetobject.get_string_member ("created_at");
			        var profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
			        var retweeted = tweetobject.get_boolean_member ("retweeted");
			        
			        if ("\n" in text)
			            text = text.replace ("\n", " ");
			            
			        // replace urls with markup links
			        Regex urls = new Regex("((http|https|ftp)://([\\S]+))");
			        text = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
			       
			        var profile_image_file = get_avatar (profile_image_url);
			        
			        home_timeline_since_id.append (new Tweet (id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, retweeted));
			       
                }                
                
                this.home_timeline_since_id.reverse ();
                this.home_timeline_since_id.foreach ((tweet) => {
                    this.home_timeline.append(tweet);
                    this.since_id_home = tweet.id;
                    
                    if (this.first_run_home == false && (this.account.screen_name != tweet.user_screen_name)) {
			            Utils.notify ("New tweet from " + tweet.user_name, tweet.text);
			        }
                    
	            });
	            
            } catch (Error e) {
                stderr.printf ("Unable to parse home_timeline.json\n");
            }
            
            this.first_run_home = false;

            return 0;
        }
        
        public int get_mentions_timeline (string count = "20") {
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
                    var tweetobject = tweetnode.get_object();
                    
                    var id = tweetobject.get_string_member ("id_str");
			        var user_name = tweetobject.get_object_member ("user").get_string_member ("name");
			        var user_screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
			        var text = tweetobject.get_string_member ("text");
			        var created_at = tweetobject.get_string_member ("created_at");
			        var profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
			        var retweeted = tweetobject.get_boolean_member ("retweeted");
			        
			        if ("\n" in text)
			            text = text.replace ("\n", " ");
			            
			        // replace urls with markup links
			        Regex urls = new Regex("((http|https|ftp)://([\\S]+))");
			        text = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
			       
			        var profile_image_file = get_avatar (profile_image_url);
			        
			        mentions_timeline_since_id.append (new Tweet (id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, retweeted));
			       
                }                
                
                this.mentions_timeline_since_id.reverse ();
                this.mentions_timeline_since_id.foreach ((tweet) => {
                    this.mentions_timeline.append(tweet);
                    this.since_id_mentions = tweet.id;
                    
                    if (this.first_run_mentions == false && (this.account.screen_name != tweet.user_screen_name)) {
			            Utils.notify ("New tweet from " + tweet.user_name, tweet.text);
			        }
                    
	            });
	            
            } catch (Error e) {
                stderr.printf ("Unable to parse mentions_timeline.json\n");
            }
            
            this.first_run_mentions = false;

            return 0;
        }
        
        public int get_own_timeline (string count = "20") {
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
                    var tweetobject = tweetnode.get_object();
                    
                    var id = tweetobject.get_string_member ("id_str");
			        var user_name = tweetobject.get_object_member ("user").get_string_member ("name");
			        var user_screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
			        var text = tweetobject.get_string_member ("text");
			        var created_at = tweetobject.get_string_member ("created_at");
			        var profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
			        var retweeted = tweetobject.get_boolean_member ("retweeted");
			        
			        if ("\n" in text)
			            text = text.replace ("\n", " ");

			        // replace urls with markup links
			        Regex urls = new Regex("((http|https|ftp)://([\\S]+))");
			        text = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
			       
			        var profile_image_file = get_avatar (profile_image_url);
			        
			        own_timeline.append (new Tweet (id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, retweeted)); 
                }
                
                own_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }
            return 0;
        }
        
        public int get_user_timeline (string user_id, string count = "20") {
            Rest.ProxyCall call = proxy.new_call();
            call.set_function ("1.1/statuses/user_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", count);
            call.add_param ("user_id", user_id);
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
                    var tweetobject = tweetnode.get_object();
                    
                    var id = tweetobject.get_string_member ("id_str");
			        var user_name = tweetobject.get_object_member ("user").get_string_member ("name");
			        var user_screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
			        var text = tweetobject.get_string_member ("text");
			        var created_at = tweetobject.get_string_member ("created_at");
			        var profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
			        var retweeted = tweetobject.get_boolean_member ("retweeted");
			        
			        if ("\n" in text)
			            text = text.replace ("\n", " ");

			        // replace urls with markup links
			        Regex urls = new Regex("((http|https|ftp)://([\\S]+))");
			        text = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
			       
			        var profile_image_file = get_avatar (profile_image_url);
			        
			        user_timeline.append (new Tweet (id, user_name, user_screen_name, text, created_at, profile_image_url, profile_image_file, retweeted)); 
                }
                
                user_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }
            
            return 0;
        }
    }
}
