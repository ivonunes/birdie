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

namespace Birdie.Media {

    public void get_avatar (Widgets.TweetList timeline) {
        timeline.boxes.reverse ();

        timeline.boxes.foreach ((tweetbox) => {
            get_single_avatar.begin (tweetbox, timeline);
        });

        timeline.boxes.reverse ();
    }

    public async void get_single_avatar (Widgets.TweetBox tweetbox, Widgets.TweetList? tweetlist = null) {

        string profile_image_url = tweetbox.tweet.profile_image_url;
        string profile_image_file = parse_profile_image_file (profile_image_url);
        string cached = Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file;

        var file = File.new_for_path (cached);

        if (file.query_exists ()) {
            tweetbox.set_avatar (cached);
            return;
        }

        yield Utils.dl_avatar (profile_image_url, cached, tweetbox);
    }

    public async void get_userbox_avatar (Widgets.UserBox userbox, bool own = false) {
        string profile_image_url = userbox.user.profile_image_url;
        string profile_image_file = parse_profile_image_file (profile_image_url);
        string cached = Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file;

        var file = File.new_for_path (cached);

        if (file.query_exists ()) {
            userbox.set_avatar (cached);
            return;
        }

        yield Utils.dl_avatar (profile_image_url, cached, null, userbox);

        if (own) {
            userbox.user.profile_image_file = profile_image_file;

            var src = File.new_for_path (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
            var dst = File.new_for_path (Environment.get_home_dir () +
                "/.local/share/birdie/avatars/" + profile_image_file);
            if (!file.query_exists ()) {
                try {
                    src.copy (dst, FileCopyFlags.NONE, null, null);
                } catch (Error e) {
                    stderr.printf ("%s\n", e.message);
                }
            }
        }
    }
}