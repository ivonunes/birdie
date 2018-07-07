// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Ivo Nunes
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivonunes@me.com>
 *              Vasco Nunes <vasco.m.nunes@me.com>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie {
    public class User {
        public string id;
        public string name;
        public string screen_name;
        public string profile_image_url;
        public string profile_image_file;
        public string location;
        public string website;
        public string desc;
        public int64 friends_count;
        public int64 followers_count;
        public int64 statuses_count;
        public bool verified;
        public string token;
        public string token_secret;
        public string service;

        public User (string id = "", string name = "",
            string screen_name = "", string profile_image_url = "",
            string profile_image_file = "", string location = "",
            string website = "", string desc = "", int64 friends_count = 0,
            int64 followers_count = 0, int64 statuses_count = 0,
            bool verified = false, string token = "", string token_secret = "",
            string service = ""
            ) {

            this.id = id;
            this.name = Utils.highlight_all (name.chomp ());
            this.screen_name = screen_name;
            this.profile_image_url = profile_image_url;
            this.profile_image_file = profile_image_file;
            this.location = Utils.highlight_all (location);
            this.website = website;
            this.desc = Utils.highlight_all (desc);
            this.friends_count = friends_count;
            this.followers_count = followers_count;
            this.statuses_count = statuses_count;
            this.verified = verified;
            this.token = token;
            this.token_secret = token_secret;
            this.service = service;
        }
    }
}
