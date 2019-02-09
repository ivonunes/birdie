// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2019 Ivo Nunes
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
    public class Cache {

        private int default_account_id;
        private SqliteDatabase db;
        private Birdie birdie;

        public Cache (Birdie birdie) {
            this.birdie = birdie;
            this.db = birdie.db;
        }

        public void set_default_account (int default_account_id) {
            this.default_account_id = default_account_id;
        }

        public void load_cached_tweets (string timeline, Widgets.TweetList tweetlist) {
            this.db.get_tweets (timeline, this.default_account_id).foreach ((tweet) => {
                tweetlist.append (tweet, this.birdie);
            });
            Media.get_avatar (tweetlist);
            Media.get_cached_media (tweetlist);
        }
    }
}
