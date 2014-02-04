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

    public void get_cached_media (Widgets.TweetList timeline) {
      timeline.boxes.reverse ();
      timeline.boxes.foreach ((tweetbox) => {
        if (tweetbox.tweet.media_url != "" || tweetbox.tweet.youtube_video != "") {
          Idle.add (() => {
            timeline.update_display (tweetbox.tweet);
            return false;
          });
        }
      });

      timeline.boxes.reverse ();
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

        return youtube_id;
    }
}