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

    public string parse_profile_image_file (string profile_image_url) {
        string profile_image_file = profile_image_url;

        if ("/" in profile_image_file)
            profile_image_file = profile_image_file.split ("/")[4] + "_" + profile_image_file.split ("/")[5];

        if (".png" in profile_image_url) {
        } else {
            if ("." in profile_image_file) {
                profile_image_file = profile_image_file.split (".")[0];
            }
            profile_image_file = profile_image_file + ".png";
        }
        return profile_image_file;
    }

    public void get_avatar (Widgets.TweetList timeline) {
        timeline.boxes.reverse ();

        timeline.boxes.foreach ((tweetbox) => {
            get_single_avatar.begin (tweetbox, timeline);
        });

        timeline.boxes.reverse ();
    }

    public void get_avatar_unthreaded (Widgets.TweetList timeline) {
        timeline.boxes.reverse ();

        timeline.boxes.foreach ((tweetbox) => {
            get_single_avatar.begin (tweetbox, timeline);
        });

        timeline.boxes.reverse ();
    }

    public async void get_single_avatar (Widgets.TweetBox tweetbox, Widgets.TweetList? tweetlist = null) {

        string profile_image_url = tweetbox.tweet.profile_image_url;
        string profile_image_file = parse_profile_image_file (profile_image_url);
        var file = File.new_for_uri (profile_image_url);
        var downloader = Utils.Downloader.get_instance ();

        try {
            file = yield downloader.download (file,
                Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file, true, tweetbox, tweetlist, tweetbox.tweet);
        } catch {}
    }

    public void get_userbox_avatar (Widgets.UserBox userbox, bool own = false) {
        var profile_image_url = userbox.user.profile_image_url;
        var profile_image_file = parse_profile_image_file (profile_image_url);

        if (!File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/" + profile_image_file).query_exists ()) {
            var d = new Utils.Downloader ();
            d.download.begin (File.new_for_uri (profile_image_url),
                Environment.get_home_dir () +
                "/.cache/birdie/" + profile_image_file, true, null, null, null, userbox);
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

    public string get_youtube_video (string youtube_video_url,
                              Widgets.TweetBox? tweetbox = null,
                              Widgets.TweetList? tweetlist = null,
                              Tweet? tweet = null) {
        string youtube_id = "";
        youtube_id = youtube_video_url.split ("v=")[1];

        if ("&" in youtube_id)
            youtube_id = youtube_id.split ("&")[0];

        if ("#" in youtube_id)
            youtube_id = youtube_id.split ("#")[0];

        if ("?" in youtube_id)
            youtube_id = youtube_id.split ("?")[0];

        var d = new Utils.Downloader ();
        d.download.begin (File.new_for_uri ("http://i3.ytimg.com/vi/" +
            youtube_id + "/mqdefault.jpg"), Environment.get_home_dir () +
            "/.cache/birdie/media/youtube_" + youtube_id + ".jpg", false, null, tweetlist, tweet);

        return  youtube_id;
    }

    public void parse_media_url (ref Json.Object entitiesobject,
                                 ref string text,
                                 ref string media_url,
                                 ref string youtube_video,
                                 Widgets.TweetList tweetlist,
                                 Tweet tweet
                                 ) {

        string expanded;
        media_url = "";
        youtube_video = "";

        if (entitiesobject.has_member("media")) {
            foreach (var media in entitiesobject.get_array_member ("media").get_elements ()) {
                media_url = media.get_object ().get_string_member ("media_url");
                media_url = get_media (media_url, null, tweetlist, tweet);
            }
        } else {
            media_url = "";
        }

       if (entitiesobject.has_member ("urls")) {
            foreach (var url in entitiesobject.get_array_member ("urls").get_elements ()) {
                expanded = url.get_object ().get_string_member ("expanded_url");

                // intercept youtube links
                if (expanded.contains ("youtube.com") || expanded.contains ("youtu.be")) {
                    if (expanded.contains ("youtu.be"))
                        expanded = expanded.replace ("youtu.be/", "youtube.com/watch?v=");
                    youtube_video = get_youtube_video (expanded, null, tweetlist, tweet);
                }

                // intercept imgur media links
                if (expanded.contains ("imgur.com/")) {
                    media_url = get_imgur_media (expanded, null, tweetlist, tweet);
                }

                // replace short urls by expanded ones in tweet text
                text = text.replace (url.get_object ().get_string_member ("url"),
                    url.get_object ().get_string_member ("expanded_url"));
            }
        }
    }

    private string get_media (string image_url,
                              Widgets.TweetBox? tweetbox = null,
                              Widgets.TweetList? tweetlist = null,
                              Tweet? tweet = null) {
        var image_file = image_url;

        if ("/" in image_file)
            image_file = image_file.split ("/")[4] + "_" + image_file.split ("/")[5];
        var d = new Utils.Downloader ();
        d.download.begin (File.new_for_uri (image_url + ":medium"),
            Environment.get_home_dir () +
            "/.cache/birdie/media/" + image_file, false, null, tweetlist, tweet);
        return image_file;
    }

    public string get_imgur_media (string url,
                                   Widgets.TweetBox? tweetbox = null,
                                   Widgets.TweetList? tweetlist = null,
                                   Tweet? tweet = null) {
        string imgur_id = "";

        if (".com/" in url)
            imgur_id = url.split (".com/")[1];

        var d = new Utils.Downloader ();
        d.download.begin (File.new_for_uri ("http://i.imgur.com/" + imgur_id + ".jpg"),
                Environment.get_home_dir () + "/.cache/birdie/media/" + imgur_id, false, null, tweetlist);
        return imgur_id;
    }

    public void show_media (string media_file) {
        var light_window = new Widgets.LightWindow ();
        Gtk.Image full_image;

        Gdk.Pixbuf pixbuf = Utils.fit_user_screen (Environment.get_home_dir ()
            + "/.cache/birdie/media/" + media_file, light_window);

        full_image = new Gtk.Image ();
        full_image.set_from_pixbuf (pixbuf);
        full_image.set_halign (Gtk.Align.CENTER);
        full_image.set_valign (Gtk.Align.CENTER);
        light_window.add (full_image);
        light_window.set_position (Gtk.WindowPosition.CENTER);

        light_window.add_events (Gdk.EventMask.KEY_PRESS_MASK);

        // connect signal to handle key events
        light_window.key_press_event.connect ((event, key) => {
            // if Space or Esc pressed, destroy dialog
            if (key.keyval == Gdk.Key.space) {
                Idle.add (() => {
                    light_window.destroy ();
                    return false;
                });
            }
            return false;
        });

        light_window.show_all ();
    }

    public void show_youtube_video (string youtube_video_id) {
        var light_window = new Widgets.LightWindow ();
        WebKit.WebView web_view = new WebKit.WebView ();
        web_view.load_html_string ("<iframe width='640' height='390' style='margin-left: -10px; margin-top: -10px; margin-bottom: -10px;' src='http://www.youtube.com/embed/" +
            youtube_video_id + "?version=3&autohide=1&controls=2&modestbranding=1&showinfo=0&showsearch=0&vq=hd720&autoplay=1' frameborder='0'</iframe>", "http://www.youtube.com/embed/");
        light_window.add (web_view);
        light_window.set_position (Gtk.WindowPosition.CENTER);
        light_window.show_all ();
    }
}