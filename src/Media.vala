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

    public void get_avatar (Widgets.TweetList timeline) {
        timeline.boxes.reverse ();

        timeline.boxes.foreach ((tweetbox) => {
            var profile_image_url = tweetbox.tweet.profile_image_url;
            var profile_image_file = profile_image_url;

            if ("/" in profile_image_file)
                profile_image_file = profile_image_file.split ("/")[4] + "_" + profile_image_file.split ("/")[5];

            if (".png" in profile_image_url) {
            } else {
                if ("." in profile_image_file) {
                    profile_image_file = profile_image_file.split (".")[0];
                }
                profile_image_file = profile_image_file + ".png";
            }

            Utils.Downloader download_handler =
                new Utils.Downloader (profile_image_url,
                Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);

            if (download_handler.download_complete && !download_handler.download_skip) {
                Utils.generate_rounded_avatar (Environment.get_home_dir () +
                    "/.cache/birdie/" + profile_image_file);
            }

            if (download_handler.download_complete) {
                tweetbox.set_avatar (Environment.get_home_dir () +
                    "/.cache/birdie/" + profile_image_file);
            }
        });

        timeline.boxes.reverse ();
    }

    public void get_userbox_avatar (Widgets.UserBox userbox, bool own = false) {
        var profile_image_url = userbox.user.profile_image_url;
        var profile_image_file = profile_image_url;

        if ("/" in profile_image_file)
            profile_image_file = profile_image_file.split ("/")[4] + "_" + profile_image_file.split ("/")[5];

        if (".png" in profile_image_url) {
        } else {
            if ("." in profile_image_file) {
                profile_image_file = profile_image_file.split (".")[0];
            }
            profile_image_file = profile_image_file + ".png";
        }

        Utils.Downloader download_handler =
            new Utils.Downloader (profile_image_url,
            Environment.get_home_dir () +
            "/.cache/birdie/" + profile_image_file);

        if (download_handler.download_complete && !download_handler.download_skip) {
            Utils.generate_rounded_avatar (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
        }

        if (download_handler.download_complete) {
            userbox.set_avatar (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
        }

        if (own) {
            userbox.user.profile_image_file = profile_image_file;

            var src = File.new_for_path (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
            var dst = File.new_for_path (Environment.get_home_dir () +
                "/.local/share/birdie/avatars/" + profile_image_file);
            try {
                src.copy (dst, FileCopyFlags.NONE, null, null);
            } catch (Error e) {
                stderr.printf ("%s\n", e.message);
            }
        }
    }
}
