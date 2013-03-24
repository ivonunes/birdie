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
    public abstract class API {
        public string CONSUMER_KEY;
        public string CONSUMER_SECRET;
        public string URL_FORMAT;
        public string REQUEST_TOKEN_URL;
        public string FUNCTION_ACCESS_TOKEN;

        public Rest.OAuthProxy proxy;

        public string since_id_home;
        public string since_id_mentions;
        public string since_id_dm;

        public User account;
        public User user;
        public GLib.List<Tweet> home_timeline;
        public GLib.List<Tweet> home_timeline_since_id;
        public GLib.List<Tweet> mentions_timeline;
        public GLib.List<Tweet> mentions_timeline_since_id;
        public GLib.List<Tweet> dm_timeline;
        public GLib.List<Tweet> dm_timeline_since_id;
        public GLib.List<Tweet> dm_sent_timeline;
        public GLib.List<Tweet> own_timeline;
        public GLib.List<Tweet> user_timeline;
        public GLib.List<Tweet> favorites;

        public Settings settings;
        public string token;
        public string token_secret;

        public Regex urls;

        public abstract string get_request ();
        public abstract int get_tokens (string pin);
        public abstract int auth ();
        public abstract int64 update (string status, string id = "");
        public abstract int destroy (string id);
        public abstract int retweet (string id);
        public abstract int favorite_create (string id);
        public abstract int favorite_destroy (string id);
        public abstract int send_direct_message (string recipient, string status);
        public abstract int get_account ();
        public abstract string get_avatar (string profile_image_url);
        public abstract string highligh_links (owned string text);
        public abstract Tweet get_tweet (Json.Node tweetnode);
        public abstract int get_home_timeline (string count = "20");
        public abstract int get_mentions_timeline (string count = "20");
        public abstract int get_direct_messages (string count = "20");
        public abstract int get_direct_messages_sent (string count = "20");
        public abstract int get_own_timeline (string count = "20");
        public abstract int get_user_timeline (string user_id, string count = "20");
        public abstract int get_favorites (string count = "20");
        public abstract Array<string> get_friendship (string source_user, string target_user);
        public abstract int create_friendship (string screen_name);
        public abstract int destroy_friendship (string screen_name);
        public abstract int create_block (string screen_name);
        public abstract int destroy_block (string screen_name);
    }
}
