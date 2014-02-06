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

namespace Birdie.Utils {
    public class Download {
        public string uri;
        public File cached_file;

        public Download (string uri, File cached_file) {
            this.uri = uri;
            this.cached_file = cached_file;
        }
    }

    public class Downloader : GLib.Object {
        private static Downloader downloader;
        private Soup.SessionAsync session;

        private GLib.HashTable<string,Download> downloads;

        public signal void downloaded (Download download);
        public signal void download_failed (Download download, GLib.Error error);

        public static Downloader get_instance () {
            if (downloader == null)
                downloader = new Downloader ();

            return downloader;
        }

        public Downloader () {
            downloads = new GLib.HashTable <string,Download> (str_hash, str_equal);

            session = new Soup.SessionAsync ();
            session.add_feature_by_type (typeof (Soup.ProxyResolverDefault));
        }

        public async File download (File remote_file,
                                    string cached_path,
                                    bool? avatar = false,
                                    Widgets.TweetBox? tweetbox = null,
                                    Widgets.TweetList? tweetlist = null,
                                    Tweet? tweet = null,
                                    Widgets.UserBox? userbox = null) throws GLib.Error {

            bool failed = false;
            var cached_file = File.new_for_path (cached_path);
            if (cached_file.query_exists () && tweetlist != null && tweet != null) {
                debug ("already available locally at '%s'. Not downloading.", cached_path);
                set_media (tweetlist, tweet);
                return cached_file;
            }

            var uri = remote_file.get_uri ();
            var download = downloads.get (uri);
            if (download != null)
                // Already being downloaded
                return yield await_download (download, cached_path);

            debug ("Downloading '%s'...", uri);
            download = new Download (uri, cached_file);
            downloads.set (uri, download);

            try {
                if (remote_file.has_uri_scheme ("http") || remote_file.has_uri_scheme ("https"))
                    yield download_from_http (download);
                else
                    yield copy_file (remote_file, cached_file);
            } catch (GLib.Error error) {
                download_failed (download, error);
                failed = true;
            } finally {
                downloads.remove (uri);
            }

            debug ("Downloaded '%s' and its now locally available at '%s'.", uri, cached_path);
            downloaded (download);

            if (tweetlist != null && tweet != null && !failed) {
                set_media (tweetlist, tweet);
            }

            return cached_file;
        }

        private void set_media (Widgets.TweetList tweetlist, Tweet tweet) {
            Idle.add (() => {
                tweetlist.update_display (tweet);
                return false;
            });
        }

        private async void download_from_http (Download download) throws GLib.Error {
            var msg = new Soup.Message ("GET", download.uri);
            var address = msg.get_address ();
            var connectable = new NetworkAddress (address.name, (uint16) address.port);
            var network_monitor = NetworkMonitor.get_default ();
            if (!(yield network_monitor.can_reach_async (connectable)))
                warning ("Failed to reach host '%s' on port '%d'", address.name, address.port);

            session.queue_message (msg, (session, msg) => {
                download_from_http.callback ();
            });
            yield;
            if (msg.status_code != Soup.KnownStatusCode.OK) {
                debug (msg.reason_phrase);
            } else {
                try {
                    yield download.cached_file.replace_contents_async (msg.response_body.data, null, false, 0, null, null);
                } catch (Error e) {
                    debug (e.message);
                }
            }
        }

        private async File? await_download (Download download,
                                            string cached_path) throws GLib.Error {
            File downloaded_file = null;
            GLib.Error download_error = null;

            File cached_file = File.new_for_path (cached_path);

            SourceFunc callback = await_download.callback;
            var downloaded_id = downloaded.connect ((downloader, downloaded) => {
                if (downloaded.uri != download.uri)
                    return;

                downloaded_file = downloaded.cached_file;
                callback ();
            });
            var downloaded_failed_id = download_failed.connect ((downloader, failed_download, error) => {
                if (failed_download.uri != download.uri)
                    return;

                download_error = error;
                callback ();
            });

            debug ("'%s' already being downloaded. Waiting for download to complete..", download.uri);
            yield; // Wait for it
            debug ("Finished waiting for '%s' to download.", download.uri);
            disconnect (downloaded_id);
            disconnect (downloaded_failed_id);

            if (download_error != null) {
                throw download_error;
            } else {
                if (downloaded_file.get_path () != cached_path)
                    yield downloaded_file.copy_async (cached_file, FileCopyFlags.NONE);
                else
                    cached_file = downloaded_file;
            }

            return cached_file;
        }

        public async void copy_file (File src_file, File dest_file, Cancellable? cancellable = null) throws GLib.Error {
            try {
                debug ("Copying '%s' to '%s'..", src_file.get_path (), dest_file.get_path ());
                yield src_file.copy_async (dest_file, 0, Priority.DEFAULT, cancellable);
                debug ("Copied '%s' to '%s'.", src_file.get_path (), dest_file.get_path ());
            } catch (IOError.EXISTS error) {}
        }
    }

    public async void dl_avatar (string url,
                                 string cached, Widgets.TweetBox? tweetbox = null,
                                 Widgets.UserBox? userbox = null) {
        var session = new Soup.Session ();
        var msg = new Soup.Message ("GET", url);
        session.send_message (msg);
        var data_stream = new MemoryInputStream.from_data ((owned)msg.response_body.data, null);

        Gdk.Pixbuf pixbuf;
        try {
            pixbuf = new Gdk.Pixbuf.from_stream (data_stream);
            double scale_x = 48.0 / pixbuf.get_width ();
            double scale_y = 48.0 / pixbuf.get_height ();
            var scaled_pixbuf = new Gdk.Pixbuf (Gdk.Colorspace.RGB, pixbuf.has_alpha, 8, 48, 48);
            pixbuf.scale (scaled_pixbuf, 0, 0, 48, 48, 0, 0, scale_x, scale_y, Gdk.InterpType.HYPER);
            scaled_pixbuf.save (cached, "png");
            yield Media.generate_rounded_avatar (cached);
            tweetbox.set_avatar.begin (cached);
        } catch (GLib.Error e) {
            debug (e.message);
        }
        yield;
    }
}