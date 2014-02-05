// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2014 Birdie Developers (http://birdieapp.github.io)
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
 */

namespace Birdie {
    public class Twitter : API {

        SqliteDatabase db;
        Birdie birdie;
        Mutex api_mutex;

        public Twitter (Birdie birdie) {

            this.db = birdie.db;
            this.birdie = birdie;

            this.CONSUMER_KEY = "T1VkU2dySk9DRFlZbjJJcDdWSGZRdw==";
            this.CONSUMER_SECRET = "UHZPdXcwWFJoVnJ5RU5yZXdGdDZWd1lGdnNoRlpwcHQxMUtkNDdvVWM=";
            this.URL_FORMAT = "https://api.twitter.com";
            this.REQUEST_TOKEN_URL = "https://api.twitter.com/oauth/request_token";
            this.FUNCTION_ACCESS_TOKEN = "oauth/access_token";

            this.CONSUMER_KEY = (string) Base64.decode (this.CONSUMER_KEY);
            this.CONSUMER_SECRET = (string) Base64.decode (this.CONSUMER_SECRET);

            this.proxy = new Rest.OAuthProxy (CONSUMER_KEY, CONSUMER_SECRET, URL_FORMAT, false);

            this.settings = new Settings ("org.birdieapp.birdie");

            this.token = "";
            this.token_secret = "";
            this.retrieve_count = settings.get_string ("retrieve-count");
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
                this.db.add_account ("twitter", token, token_secret);
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
                proxy.set_token (token);
                proxy.set_token_secret (token_secret);
            }

            this.account_id = db.get_account_id ();
            this.since_id_home = this.db.get_since_id ("tweets", this.account_id);
            this.since_id_mentions = this.db.get_since_id ("mentions", this.account_id);
            this.since_id_dm = this.db.get_since_id ("dm_inbox", this.account_id);
            this.since_id_dm_outbox = this.db.get_since_id ("dm_outbox", this.account_id);
            this.since_id_own = this.db.get_since_id ("own", this.account_id);
            this.since_id_favorites = this.db.get_since_id ("favorites", this.account_id);

            return 0;
        }

        public override int64 update (string status, string id = "") {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/update.json");
            call.set_method ("POST");
            call.add_param ("status", status);
            if (id != "")
                call.add_param ("in_reply_to_status_id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return 1;
                }

                var root = parser.get_root ();
                var userobject = root.get_object ();

                var user_id = userobject.get_int_member ("id");
                api_mutex.unlock ();
                return user_id;
            } catch (Error e) {
                stderr.printf ("Unable to parse update.json\n");
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int64 update_with_media (string status,
            string id, string media_uri, out string media_out) {

            string link = "";
            var imgur = new Media.Imgur ();

            try {
                link = imgur.upload (media_uri);
            } catch (Error e) {
                critical ("Error uploading image to imgur: %s", e.message);
            }

            media_out = link;

            if (link == "")
                return 1;

            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/update.json");
            call.set_method ("POST");
            call.add_param ("status", status + " " + link);
            if (id != "")
                call.add_param ("in_reply_to_status_id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return 1;
                }
                var root = parser.get_root ();
                var userobject = root.get_object ();

                var user_id = userobject.get_int_member ("id");
                api_mutex.unlock ();
                return user_id;
            } catch (Error e) {
                stderr.printf ("Unable to parse update.json\n");
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int destroy (string id) {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/destroy/" + id + ".json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int retweet (string id) {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/retweet/" + id + ".json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                api_mutex.unlock ();
                if (e.message == "Forbidden")
                    return 0;
                critical (e.message);
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int favorite_create (string id) {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/favorites/create.json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int favorite_destroy (string id) {
            // setup call
            api_mutex.lock ();
            debug (id);
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/favorites/destroy.json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int send_direct_message (string recipient, string status) {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/direct_messages/new.json");
            call.set_method ("POST");
            call.add_param ("screen_name", recipient);
            call.add_param ("text", status);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int64 send_direct_message_with_media (string recipient, string status,
            string media_uri, out string media_out) {

            string link = "";
            var imgur = new Media.Imgur ();

            try {
                link = imgur.upload (media_uri);
            } catch (Error e) {
                critical ("Error uploading image to imgur: %s", e.message);
            }

            media_out = link;

            if (link == "")
                return 1;

            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/direct_messages/new.json");
            call.set_method ("POST");
            call.add_param ("screen_name", recipient);
            call.add_param ("text", status + " " + link);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return 1;
                }
                var root = parser.get_root ();
                var userobject = root.get_object ();

                var user_id = userobject.get_int_member ("id");
                api_mutex.unlock ();
                return user_id;
            } catch (Error e) {
                stderr.printf ("Unable to parse update.json\n");
            }

            api_mutex.unlock ();
            return 0;
        }

        public override int get_account () {
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/account/verify_credentials.json");
            call.set_method ("GET");
            call.add_param ("entities", "true");

            string id = "";
            string name = "";
            string screen_name = "";
            string profile_image_url = "";
            string profile_image_file = "";
            string website = "";
            string desc = "";
            string location = "";

            int64 friends_count = 0;
            int64 followers_count = 0;
            int64 statuses_count = 0;
            bool verified = false;

            try { call.sync (); } catch (Error e) {
                critical (e.message);
                return 1;
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else
                    return 1;

                var root = parser.get_root ();
                var userobject = root.get_object ();

                id = userobject.get_string_member ("id_str");
                name = userobject.get_string_member ("name");
                screen_name = userobject.get_string_member ("screen_name");
                profile_image_url = userobject.get_string_member ("profile_image_url");

                if (userobject.has_member ("location") &&
                    userobject.get_string_member ("location") != null) {
                     location = userobject.get_string_member ("location");
                }

                if (userobject.has_member ("url") &&
                    userobject.get_string_member ("url") != null) {
                     website = userobject.get_object_member ("entities").get_object_member ("url").
                                get_array_member ("urls").get_object_element (0).get_string_member ("display_url");
                }

                if (userobject.has_member ("description") &&
                    userobject.get_string_member ("description") != null) {
                     desc = userobject.get_string_member ("description");
                }

                friends_count = userobject.get_int_member ("friends_count");
                followers_count = userobject.get_int_member ("followers_count");
                statuses_count = userobject.get_int_member ("statuses_count");
                verified = userobject.get_boolean_member ("verified");

                account = new User (id, name, screen_name,
                    profile_image_url, profile_image_file, location, website, desc,
                    friends_count, followers_count, statuses_count, verified,
                    this.token, this.token_secret
                );

            } catch (Error e) {
                stderr.printf ("Unable to parse verify_credentials.json\n");
            }
            return 0;
        }

        public void get_user (Json.Node tweetnode) {

            string id = "";
            string name = "";
            string screen_name = "";
            string profile_image_url = "";
            string profile_image_file = "";
            string location = "";
            string website = "";
            string description = "";

            int64 friends_count = 0;
            int64 followers_count = 0;
            int64 statuses_count = 0;
            bool verified = false;

            var tweetobject = tweetnode.get_object();

            id = tweetobject.get_object_member ("user").get_string_member ("id_str");
            name = tweetobject.get_object_member ("user").get_string_member ("name");
            screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
            profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
            profile_image_file = Media.parse_profile_image_file (profile_image_url);

            if (tweetobject.get_object_member ("user").has_member("location") &&
                 tweetobject.get_object_member ("user").get_string_member ("location") != null) {
                location = Utils.escape_markup (tweetobject.get_object_member ("user").get_string_member ("location"));
            }

            if (tweetobject.get_object_member ("user").has_member("url") &&
                 tweetobject.get_object_member ("user").get_string_member ("url") != null) {
                website = tweetobject.get_object_member ("user").get_object_member ("entities").get_object_member ("url").
                           get_array_member ("urls").get_object_element (0).get_string_member ("display_url");
            }

            if (tweetobject.get_object_member ("user").has_member("description") &&
                 tweetobject.get_object_member ("user").get_string_member ("description") != null) {
                description = Utils.escape_markup (tweetobject.get_object_member ("user").get_string_member ("description"));
            }

            friends_count = tweetobject.get_object_member ("user").get_int_member ("friends_count");
            followers_count = tweetobject.get_object_member ("user").get_int_member ("followers_count");
            statuses_count = tweetobject.get_object_member ("user").get_int_member ("statuses_count");
            verified =  tweetobject.get_object_member ("user").get_boolean_member ("verified");

            this.user = new User (id, name, screen_name,
                profile_image_url, profile_image_file, location, website, description,
                friends_count, followers_count, statuses_count, verified
            );
        }

        public override Tweet get_tweet (Json.Node tweetnode, Widgets.TweetList? tweetlist = null) {

            string id = "";
            string user_name = "";
            string user_screen_name = "";
            string text = "";
            string created_at = "";
            string profile_image_url = "";
            string profile_image_file = "";
            string retweeted_by = "";
            string retweeted_by_name = "";
            string media_url = "";
            string youtube_video = "";
            string? in_reply_to_screen_name = "";
            string? in_reply_to_status_id = "";

            bool retweeted = false;
            bool favorited = false;
            bool verified = false;

            var tweetobject = tweetnode.get_object();
            var actual_id = tweetobject.get_string_member ("id_str");
            var retweet = tweetobject.get_member ("retweeted_status");

            if (retweet != null) {
                retweeted_by = tweetobject.get_object_member ("user").get_string_member ("screen_name");
                retweeted_by_name = tweetobject.get_object_member ("user").get_string_member ("name");
                tweetobject = tweetobject.get_object_member ("retweeted_status");
            }

            id = tweetobject.get_string_member ("id_str");
            retweeted = tweetobject.get_boolean_member ("retweeted");
            favorited = tweetobject.get_boolean_member ("favorited");
            user_name = tweetobject.get_object_member ("user").get_string_member ("name");
            user_screen_name = tweetobject.get_object_member ("user").get_string_member ("screen_name");
            text = tweetobject.get_string_member ("text");
            created_at = tweetobject.get_string_member ("created_at");
            profile_image_url = tweetobject.get_object_member ("user").get_string_member ("profile_image_url");
            verified = tweetobject.get_object_member ("user").get_boolean_member ("verified");
            in_reply_to_screen_name = tweetobject.get_string_member ("in_reply_to_screen_name");
            in_reply_to_status_id = tweetobject.get_string_member ("in_reply_to_status_id_str");

            if (in_reply_to_screen_name == null)
                in_reply_to_screen_name = "";
            if (in_reply_to_status_id == null)
                in_reply_to_status_id = "";

            Json.Object entitiesobject = tweetobject.get_object_member ("entities");

            profile_image_file = Media.parse_profile_image_file (profile_image_url);

            var tweet =  new Tweet (id, actual_id, user_name, user_screen_name,
                Utils.highlight_all (text), created_at, profile_image_url, profile_image_file,
                retweeted, favorited, false, in_reply_to_screen_name,
                retweeted_by, retweeted_by_name, media_url, youtube_video, verified, in_reply_to_status_id);

            Media.parse_media_url (ref entitiesobject, ref text, ref media_url, ref youtube_video, tweetlist, tweet);

            tweet.youtube_video = youtube_video;
            tweet.media_url = media_url;
            tweet.text = Utils.highlight_all (text);
            return tweet;
        }

        public TwitterList get_list (Json.Node listnode) {
            string id = "";
            string full_name = "";
            string description = "";
            string created_at = "";

            var listobject = listnode.get_object();

            id = listobject.get_string_member ("id_str");
            full_name = listobject.get_string_member ("full_name");
            description = listobject.get_string_member ("description");
            created_at = listobject.get_string_member ("created_at");

            return new TwitterList (id, full_name, description, created_at);
        }

        public override Tweet get_single_tweet (string tweet_id) {
            api_mutex.lock ();
            Tweet tweet = new Tweet ();

            // setup call
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/show.json");
            call.set_method ("GET");
            call.add_param ("id", tweet_id);

            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return tweet;
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return tweet;
                }

                var node = parser.get_root ();
                tweet = this.get_tweet (node);
            } catch (Error e) {
                stderr.printf ("Unable to parse show.json\n");
            }
            api_mutex.unlock ();

            return tweet;
        }

      public override void get_home_timeline () {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/home_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            if (this.since_id_home != "" && this.since_id_home != null)
                call.add_param ("since_id", this.since_id_home);

            Rest.ProxyCallAsyncCallback callback = get_home_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_home_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                // clear since_id list
                this.home_timeline.foreach ((tweet) => {
                    this.home_timeline.remove (tweet);
                });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.home_list);
                    home_timeline.append (tweet);
                    this.db.add_tweet.begin (tweet, "tweets", this.account_id);
                }

                this.home_timeline.reverse ();
                this.home_timeline.foreach ((tweet) => {
                    this.since_id_home = tweet.actual_id;
                });

                this.db.purge_tweets ("tweets");

            } catch (Error e) {
                stderr.printf ("Unable to parse home_timeline.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_home_ui ();
        }

        // get older statuses

        public override void get_older_home_timeline () {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/home_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            call.add_param ("max_id", this.birdie.home_list.get_oldest ());

            Rest.ProxyCallAsyncCallback callback = get_older_home_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_older_home_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                this.home_timeline.foreach ((tweet) => {
                    this.home_timeline.remove (tweet);
                });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.home_list);
                    home_timeline.append (tweet);
                }

                this.home_timeline.foreach ((tweet) => {
                    this.max_id_home = tweet.actual_id;
                });

            } catch (Error e) {
                stderr.printf ("Unable to parse home_timeline.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_older_home_ui ();
        }

        public override void get_older_mentions_timeline () {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/mentions_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            call.add_param ("max_id", this.birdie.mentions_list.get_oldest ());

            Rest.ProxyCallAsyncCallback callback = get_older_mentions_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_older_mentions_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                this.mentions_timeline.foreach ((tweet) => {
                    this.mentions_timeline.remove (tweet);
                });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.mentions_list);
                    mentions_timeline.append (tweet);
                }

                this.mentions_timeline.foreach ((tweet) => {
                    this.max_id_home = tweet.actual_id;
                });

            } catch (Error e) {
                stderr.printf ("Unable to parse home_timeline.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_older_mentions_ui ();
        }

        public override void get_older_search_timeline (string search_term) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/search/tweets.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            call.add_param ("q", search_term);
            call.add_param ("max_id", this.birdie.search_list.get_oldest ());
            Rest.ProxyCallAsyncCallback callback = get_older_search_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_older_search_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            this.search_timeline.foreach ((tweet) => {
                this.search_timeline.remove (tweet);
            });

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                var tweetobject = root.get_object ();
                var statuses_member = tweetobject.get_array_member ("statuses");

                foreach (var tweetnode in statuses_member.get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.search_list);
                    search_timeline.append (tweet);
                }

                search_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse tweets.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_older_search_ui ();
        }

        //

        public override void get_mentions_timeline () {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/mentions_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", retrieve_count);
            if (this.since_id_mentions != "" && this.since_id_mentions != null)
                call.add_param ("since_id", this.since_id_mentions);

            Rest.ProxyCallAsyncCallback callback = get_mentions_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_mentions_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                // clear since_id list
                this.mentions_timeline.foreach ((tweet) => {
                    this.mentions_timeline.remove(tweet);
                });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.mentions_list);
                    mentions_timeline.append (tweet);
                    this.db.add_tweet.begin (tweet, "mentions", this.account_id);
                }

                this.mentions_timeline.reverse ();
                this.mentions_timeline.foreach ((tweet) => {
                    this.since_id_mentions = tweet.actual_id;
                });

                this.db.purge_tweets ("mentions");

            } catch (Error e) {
                stderr.printf ("Unable to parse mentions_timeline.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_mentions_ui ();
        }

        public override void get_direct_messages () {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/direct_messages.json");
            call.set_method ("GET");
            call.add_param ("count", retrieve_count);
            if (this.since_id_dm != "" && this.since_id_dm != null)
                call.add_param ("since_id", this.since_id_dm);

            Rest.ProxyCallAsyncCallback callback = get_dm_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_dm_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            string media_url = "";
            string youtube_video = "";

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                // clear since_id list
                this.dm_timeline.foreach ((tweet) => {
                    this.dm_timeline.remove(tweet);
                });

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweetobject = tweetnode.get_object();

                    var id = tweetobject.get_string_member ("id_str");
                    var user_name = tweetobject.get_object_member ("sender").get_string_member ("name");
                    var user_screen_name = tweetobject.get_object_member ("sender").get_string_member ("screen_name");
                    var text = tweetobject.get_string_member ("text");
                    //text = Utils.highlight_all(text);
                    var created_at = tweetobject.get_string_member ("created_at");
                    var profile_image_url = tweetobject.get_object_member ("sender").get_string_member ("profile_image_url");
                    var profile_image_file = Media.parse_profile_image_file (profile_image_url);

                    Json.Object entitiesobject = tweetobject.get_object_member ("entities");

                    var tweet = new Tweet (id, id, user_name,
                        user_screen_name, text, created_at,
                        profile_image_url, profile_image_file,
                        false, false, true, "", "", "", media_url, youtube_video);

                    Media.parse_media_url (ref entitiesobject, ref text, ref media_url, ref youtube_video, this.birdie.dm_list, tweet);

                    tweet.youtube_video = youtube_video;
                    tweet.media_url = media_url;
                    tweet.text = Utils.highlight_all (text);

                    dm_timeline.append (tweet);
                    this.db.add_tweet.begin (tweet, "dm_inbox", this.account_id);
                }

                this.dm_timeline.reverse ();
                this.dm_timeline.foreach ((tweet) => {
                    this.since_id_dm = tweet.actual_id;
                });

                this.db.purge_tweets ("dm_inbox");

            } catch (Error e) {
                stderr.printf ("Unable to parse direct_messages.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_dm_ui ();
        }

        public override void get_direct_messages_sent () {
            // setup call
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/direct_messages/sent.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            if (this.since_id_dm_outbox != "" && this.since_id_dm_outbox != null)
                call.add_param ("since_id", this.since_id_dm_outbox);
            Rest.ProxyCallAsyncCallback callback = get_dm_sent_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_dm_sent_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweetobject = tweetnode.get_object();

                    var id = tweetobject.get_string_member ("id_str");
                    var user_name = tweetobject.get_object_member ("sender").get_string_member ("name");
                    var user_screen_name = tweetobject.get_object_member ("recipient").get_string_member ("screen_name");
                    var text = tweetobject.get_string_member ("text");
                    text = Utils.highlight_all(text);
                    var created_at = tweetobject.get_string_member ("created_at");
                    var profile_image_url = tweetobject.get_object_member ("sender").get_string_member ("profile_image_url");
                    var profile_image_file = Media.parse_profile_image_file (profile_image_url);

                    var tweet = new Tweet (id, id, user_name,
                        user_screen_name, text, created_at,
                        profile_image_url, profile_image_file,
                        false, false, true);

                    dm_sent_timeline.append (tweet);
                    this.db.add_tweet.begin (tweet, "dm_outbox", this.account_id);
                }

                this.dm_sent_timeline.reverse ();

                this.db.purge_tweets ("dm_outbox");

            } catch (Error e) {
                stderr.printf ("Unable to parse sent.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_dm_sent_ui ();
        }

        public override void get_own_timeline () {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/user_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            if (this.since_id_own != "" && this.since_id_own != null)
                call.add_param ("since_id", this.since_id_own);
            call.add_param ("user_id", this.account.id);
            Rest.ProxyCallAsyncCallback callback = get_own_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_own_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.own_list);

                    if (tweet.retweeted_by != "") {
                        tweet.retweeted = true;
                    }

                    own_timeline.append (tweet);
                    this.db.add_tweet.begin (tweet, "own", this.account_id);
                }
                own_timeline.reverse ();
                this.db.purge_tweets ("own");
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_own_timeline_ui ();
        }

        public override void get_favorites () {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/favorites/list.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            if (this.since_id_favorites != "" && this.since_id_favorites != null)
                call.add_param ("since_id", this.since_id_favorites);
            call.add_param ("user_id", this.account.id);
            Rest.ProxyCallAsyncCallback callback = get_favorites_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_favorites_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.favorites);

                    if (tweet.retweeted_by != "") {
                        tweet.retweeted = true;
                    }

                    favorites.append (tweet);
                    this.db.add_tweet.begin (tweet, "favorites", this.account_id);
                }
                this.db.purge_tweets ("favorites");
                favorites.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse favorites.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_favorites_ui ();
        }

        public override Array<string> get_followers (string screen_name) {
            Array<string> followers = new Array<string> ();
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/followers/ids.json");
            call.set_method ("GET");
            call.add_param ("stringify_ids", "true");
            call.add_param ("screen_name", screen_name);

            try { call.sync (); } catch (Error e) {
                critical (e.message);
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return new Array<string> ();
                }

                var root = parser.get_root ();
                var userobject = root.get_object ();
                var ids = userobject.get_object_member ("ids");
                followers = (Array<string>)ids;
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }
            api_mutex.unlock ();
            return followers;
        }

        public override Array<string> get_friendship (string source_user, string target_user) {
            Array<string> friendship = new Array<string> ();

            bool following = false;
            bool blocking = false;
            bool followed = false;

            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/friendships/show.json");
            call.set_method ("GET");
            call.add_param ("source_screen_name", source_user);
            call.add_param ("target_screen_name", target_user);

            try { call.sync (); } catch (Error e) {
                critical (e.message);
            }

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return new Array<string> ();
                }

                var root = parser.get_root ();
                var userobject = root.get_object ();
                var usermember = userobject.get_object_member ("relationship");

                following = usermember.get_object_member ("source").get_boolean_member ("following");
                blocking = usermember.get_object_member ("source").get_boolean_member ("blocking");
                followed = usermember.get_object_member ("source").get_boolean_member ("followed_by");

            } catch (Error e) {
                stderr.printf ("Unable to parse sent.json\n");
            }

            api_mutex.unlock ();

            friendship.append_val (following.to_string ());
            friendship.append_val (blocking.to_string ());
            friendship.append_val (followed.to_string ());

            return friendship;
        }

        public override int create_friendship (string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/friendships/create.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int destroy_friendship (string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/friendships/destroy.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int create_block (string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/blocks/create.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int destroy_block (string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/blocks/destroy.json");
            call.set_method ("POST");
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int destroy_dm (string id) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/direct_messages/destroy.json");
            call.set_method ("POST");
            call.add_param ("id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override void get_user_timeline (string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/statuses/user_timeline.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            call.add_param ("screen_name", screen_name);
            Rest.ProxyCallAsyncCallback callback = get_user_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_user_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            this.user_timeline.foreach ((tweet) => {
                this.user_timeline.remove (tweet);
            });

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.user_list);
                    user_timeline.append (tweet);
                    this.get_user (tweetnode);
                }

                user_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse user_timeline.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_user_timeline_ui ();
        }

        public override void get_search_timeline (string search_term) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/search/tweets.json");
            call.set_method ("GET");
            call.add_param ("count", this.retrieve_count);
            call.add_param ("q", search_term);
            Rest.ProxyCallAsyncCallback callback = get_search_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_search_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            this.search_timeline.foreach ((tweet) => {
                this.search_timeline.remove (tweet);
            });

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                var tweetobject = root.get_object ();
                var statuses_member = tweetobject.get_array_member ("statuses");

                foreach (var tweetnode in statuses_member.get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.search_list);
                    search_timeline.append (tweet);
                }

                search_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse tweets.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_search_ui ();
        }

        public override void get_lists () {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/list.json");
            call.set_method ("GET");
            call.add_param ("reverse", "true");
            Rest.ProxyCallAsyncCallback callback = get_lists_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_lists_response (
            Rest.ProxyCall call, Error? error, Object? obj) {

            Idle.add (() => {
                this.birdie.lists.clear ();
                return false;
            });

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                foreach (var listnode in root.get_array ().get_elements ()) {
                    var list = get_list (listnode);
                    Idle.add (() => {
                        this.birdie.lists.append (list, this.birdie);
                        return false;
                    });
                }
            } catch (Error e) {
                stderr.printf ("Unable to parse list.json\n");
            }

            api_mutex.unlock ();
        }

        public override void get_list_timeline (string id) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/statuses.json");
            call.set_method ("GET");
            call.add_param ("list_id", id);
            Rest.ProxyCallAsyncCallback callback = get_list_timeline_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void get_list_timeline_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            this.list_timeline.foreach ((tweet) => {
                this.list_timeline.remove (tweet);
            });

            try {
                var parser = new Json.Parser ();

                if (parser != null)
                    parser.load_from_data ((string) call.get_payload (), -1);
                else {
                    api_mutex.unlock ();
                    return;
                }

                var root = parser.get_root ();

                foreach (var tweetnode in root.get_array ().get_elements ()) {
                    var tweet = this.get_tweet (tweetnode, this.birdie.list_list);
                    list_timeline.append (tweet);
                }

                list_timeline.reverse ();
            } catch (Error e) {
                stderr.printf ("Unable to parse statuses.json\n");
            }
            api_mutex.unlock ();
            this.birdie.update_list_ui ();
        }

        public override int unsubscribe_list (string id) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/subscribers/destroy.json");
            call.set_method ("POST");
            call.add_param ("list_id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int destroy_list (string id) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/destroy.json");
            call.set_method ("POST");
            call.add_param ("list_id", id);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override void create_list (string name, string description) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/create.json");
            call.set_method ("POST");
            call.add_param ("name", name);
            call.add_param ("description", description);
            call.add_param ("mode", "private");
            Rest.ProxyCallAsyncCallback callback = create_list_response;
            try {
                call.run_async (callback);
            } catch (Error e) {
                critical (e.message);
            }
        }

        protected void create_list_response (
            Rest.ProxyCall call, Error? error, Object? obj) {
            api_mutex.unlock ();
            this.get_lists ();
        }

        public override int add_to_list (string list_id, string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/members/create.json");
            call.set_method ("POST");
            call.add_param ("list_id", list_id);
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }

        public override int remove_from_list (string list_id, string screen_name) {
            api_mutex.lock ();
            Rest.ProxyCall call = proxy.new_call ();
            call.set_function ("1.1/lists/members/destroy.json");
            call.set_method ("POST");
            call.add_param ("list_id", list_id);
            call.add_param ("screen_name", screen_name);
            try { call.sync (); } catch (Error e) {
                critical (e.message);
                api_mutex.unlock ();
                return 1;
            }
            api_mutex.unlock ();
            return 0;
        }
    }
}
