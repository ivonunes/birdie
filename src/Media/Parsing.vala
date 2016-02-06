// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2016 Birdie Developers (http://birdieapp.github.io)
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
 *              Nathan Dyer <mail@nathandyer.me>
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

    public void parse_media_url (ref Json.Object entitiesobject,
                                 ref string text,
                                 ref string media_url,
                                 ref string youtube_video,
                                 Widgets.TweetList? tweetlist = null,
                                 Tweet? tweet = null
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

                // intercept instagram links
                if (expanded.contains ("instagram")) {
                    media_url = get_instagram_media (expanded, null, tweetlist, tweet);
                }

                // intercept vine links
                if (expanded.contains ("vine.co")) {
                    youtube_video = expanded;
                }

                // replace short urls by expanded ones in tweet text
                text = text.replace (url.get_object ().get_string_member ("url"),
                    url.get_object ().get_string_member ("expanded_url"));
            }
        }
    }
}