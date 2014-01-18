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
    Mutex avatar_mutex;

    public void get_avatar (Widgets.TweetList timeline) {
        if (Utils.check_internet_connection ()) {
            new Thread<void*> (null, () => {
                avatar_mutex.lock ();
                timeline.boxes.reverse ();

                timeline.boxes.foreach ((tweetbox) => {
                    get_single_avatar (tweetbox, true);
                });

                timeline.boxes.reverse ();
                avatar_mutex.unlock ();
                return null;
            });
        }
    }

    public void get_avatar_unthreaded (Widgets.TweetList timeline) {
        if (Utils.check_internet_connection ()) {
            avatar_mutex.lock ();
            timeline.boxes.reverse ();

            timeline.boxes.foreach ((tweetbox) => {
                get_single_avatar (tweetbox, true);
            });

            timeline.boxes.reverse ();
            avatar_mutex.unlock ();
        }
    }

    public void get_single_avatar (Widgets.TweetBox tweetbox, bool ignore_mutex = false) {
        if (!ignore_mutex)
            avatar_mutex.lock ();

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

        if (!File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file).query_exists ()) {
            new Utils.Downloader (profile_image_url,
                Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
            
            Utils.generate_rounded_avatar (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
        }
        
        Idle.add (() => {
            tweetbox.set_avatar (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);
            return false;
        });

        if (!ignore_mutex)
            avatar_mutex.unlock ();
    }

    public void get_userbox_avatar (Widgets.UserBox userbox, bool own = false) {
        if (Utils.check_internet_connection ()) {
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

            if (!File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file).query_exists ()) {
                new Utils.Downloader (profile_image_url,
                    Environment.get_home_dir () +
                    "/.cache/birdie/" + profile_image_file);
            
                Utils.generate_rounded_avatar (Environment.get_home_dir () +
                    "/.cache/birdie/" + profile_image_file);
            }

            userbox.set_avatar (Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file);

            if (own) {
                userbox.user.profile_image_file = profile_image_file;

                var src = File.new_for_path (Environment.get_home_dir () +
                    "/.cache/birdie/" + profile_image_file);
                var dst = File.new_for_path (Environment.get_home_dir () +
                    "/.local/share/birdie/avatars/" + profile_image_file);
                if (!dst.query_exists ()) {
                    try {
                        src.copy (dst, FileCopyFlags.NONE, null, null);
                    } catch (Error e) {
                        stderr.printf ("%s\n", e.message);
                    }
                }
            }
        }
    }

    public string get_youtube_video (string youtube_video_url) {
        if (Utils.check_internet_connection ()) {
            string youtube_id = "";
            youtube_id = youtube_video_url.split ("v=")[1];

            if ("&" in youtube_id)
                youtube_id = youtube_id.split ("&")[0];

            if ("#" in youtube_id)
                youtube_id = youtube_id.split ("#")[0];

            if ("?" in youtube_id)
                youtube_id = youtube_id.split ("?")[0];

            if (!File.new_for_path (Environment.get_home_dir () +
                "/.cache/birdie/media/youtube_" + youtube_id + ".jpg").query_exists ()) {
                new Utils.Downloader ("http://i3.ytimg.com/vi/" +
                    youtube_id + "/mqdefault.jpg", Environment.get_home_dir () +
                    "/.cache/birdie/media/youtube_" + youtube_id + ".jpg");
            }

            if (File.new_for_path (Environment.get_home_dir () +
                "/.cache/birdie/media/youtube_" + youtube_id + ".jpg").query_exists ()) {
                return youtube_id;
            } else {
                return "";
            }
        } else {
            return "";
        }
    }

    public string get_imgur_media (string url) {
        if (Utils.check_internet_connection ()) {
            string imgur_id = "";

            if (".com/" in url)
                imgur_id = url.split (".com/")[1];

            if (!File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/media/" + imgur_id).query_exists ()) {
                new Utils.Downloader ("http://i.imgur.com/" + imgur_id + ".jpg",
                    Environment.get_home_dir () + "/.cache/birdie/media/" + imgur_id);
            }

            if (File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/media/" + imgur_id).query_exists ()) {
                return imgur_id;
            } else {
                return "";
            }
        } else {
            return "";
        }
    }
}
