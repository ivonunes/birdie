// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Amuza Limited
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@amuza.uk>
 *              Vasco Nunes <vasco@amuza.uk>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie {
    public class Tweet {
        public string id;
        public string actual_id;
        public string user_name;
        public string user_screen_name;
        public string text;
        public string created_at;
        public string profile_image_url;
        public string profile_image_file;
        public string in_reply_to_screen_name;
        public string retweeted_by;
        public string retweeted_by_name;
        public string media_url;
        public string youtube_video;
        public string in_reply_to_status_id;
        public bool verified;
        public bool retweeted;
        public bool favorited;
        public bool dm;

        public Tweet (string id = "", string actual_id = "",
         string user_name = "", string user_screen_name = "",
         string text = "", string created_at = "",
         string profile_image_url = "", string profile_image_file = "",
         bool retweeted = false, bool favorited = false,
         bool dm = false, string in_reply_to_screen_name = "",
         string retweeted_by = "", string retweeted_by_name = "",
         string media_url = "", string youtube_video = "",
         bool verified = false, string in_reply_to_status_id = "") {

            this.id = id;
            this.actual_id = actual_id;
            this.user_name = user_name;
            this.user_screen_name = user_screen_name;
            this.text = text;
            this.created_at = created_at;
            this.profile_image_url = profile_image_url;
            this.profile_image_file = profile_image_file;
            this.retweeted = retweeted;
            this.favorited = favorited;
            this.dm = dm;
            this.in_reply_to_screen_name = in_reply_to_screen_name;
            this.retweeted_by = retweeted_by;
            this.retweeted_by_name = retweeted_by_name;
            this.media_url = media_url;
            this.youtube_video = youtube_video;
            this.verified = verified;
            this.in_reply_to_status_id = in_reply_to_status_id;
        }
    }
}
