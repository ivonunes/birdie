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

namespace Birdie.Utils {

    public class Indicator : GLib.Object {
#if HAVE_LIBMESSAGINGMENU
        Birdie birdie;
        private MessagingMenu.App? app = null;

        public signal void application_activated(uint32 timestamp);
        //public signal void mentions_activated(Geary.Folder folder, uint32 timestamp);
        public signal void tweet_activated(uint32 timestamp);

        public Indicator (Birdie birdie) {
            this.birdie = birdie;

            app = new MessagingMenu.App("birdie.desktop");
            app.register();
            app.activate_source.connect(on_activate_source);

            debug("Registered messaging-menu");

            update_mentions_indicator ();
            update_dm_indicator ();
            update_new_tweet_indicator ();
        }
        
        public static Indicator create(Birdie birdie) {
            Indicator? indicator = null;
            
            if (indicator == null)
                indicator = new Indicator (birdie);
            
            assert(indicator != null);
            
            return indicator;
        }
        
        // Returns time as a uint32 (suitable for signals if event doesn't supply it)
        protected uint32 now() {
            return (uint32) TimeVal().tv_sec;
        }

        private void on_activate_source(string source_id) {
            switch (source_id) {
                case "tweets":
                    this.birdie.switch_timeline ("home");
                    this.birdie.activate ();
                    update_tweets_indicator ();
                    break;
                case "mentions":
                    this.birdie.switch_timeline ("mentions");
                    this.birdie.activate ();
                    update_mentions_indicator ();
                    break;
                case "dm":
                    this.birdie.switch_timeline ("dm");
                    this.birdie.activate ();
                    update_dm_indicator ();
                    break;
                case "newtweet":
                    Widgets.TweetDialog dialog = new Widgets.TweetDialog (birdie);
                    dialog.show_all ();
                    update_new_tweet_indicator ();
                    break;
            }
        }

        public void update_tweets_indicator(int count = 0) {
            if (app.has_source("tweets"))
                app.set_source_count("tweets", count);
            else
                app.append_source_with_count("tweets", null,
                    _("Tweets"), count);
            
            if (count > 0)
                app.draw_attention("tweets");
            else
                app.remove_attention("tweets");

            if (app.has_source("newtweet")) {
                app.remove_source ("newtweet");
                update_new_tweet_indicator ();
            }
        }

        public void update_mentions_indicator(int count = 0) {
            if (app.has_source("mentions"))
                app.set_source_count("mentions", count);
            else
                app.append_source_with_count("mentions", null,
                    _("Mentions"), count);
            
            if (count > 0)
                app.draw_attention("mentions");
            else
                app.remove_attention("mentions");

            if (app.has_source("newtweet")) {
                app.remove_source ("newtweet");
                update_new_tweet_indicator ();
            }
        }

        public void update_dm_indicator(int count = 0) {
            if (app.has_source("dm"))
                app.set_source_count("dm", count);
            else
                app.append_source_with_count("dm", null,
                    _("Direct Messages"), count);
            
            if (count > 0)
                app.draw_attention("dm");
            else
                app.remove_attention("dm");

            if (app.has_source("newtweet")) {
                app.remove_source ("newtweet");
                update_new_tweet_indicator ();
            }
        }

        public void update_new_tweet_indicator() {
            if (!app.has_source("newtweet"))
                app.append_source_with_count("newtweet", null,
                    _("New Tweet"), 0);
        }

        public void clean_tweets_indicator () {
            if (app.has_source("tweets"))
                app.remove_attention ("tweets");
        }

        public void clean_mentions_indicator () {
            if (app.has_source("mentions"))
                app.remove_attention ("mentions");
        }

        public void clean_dm_indicator () {
            if (app.has_source("mentions"))
                app.remove_attention ("mentions");
        }
#elif HAVE_LIBINDICATE
        public int unread { get; set; }

        private Indicate.Server indicator = null;
        private List<Indicate.Indicator> items;
        private Indicate.Indicator tweets;
        private Indicate.Indicator mentions;
        private Indicate.Indicator new_tweet;
        private Indicate.Indicator dm;

        Birdie birdie;

        public Indicator (Birdie birdie) {
            this.birdie = birdie;

            indicator = Indicate.Server.ref_default ();
            indicator.set_type ("message.email");

            string desktop_file = Constants.DATADIR + "/applications/birdie.desktop";

            if (desktop_file == null) {
                debug ("Unable to setup libindicate support: no desktop file found");
                return;
            }

            indicator.set_desktop_file (desktop_file);

            // indicator entries
            this.tweets = add_indicator (_("Tweets"));
            this.mentions = add_indicator (_("Mentions"));
            this.dm = add_indicator (_("Direct Messages"));
            this.new_tweet = add_indicator (_("New Tweet"));
            //

            new_tweet.show ();

            // signal connections
            indicator.server_display.connect (on_user_display);
            new_tweet.user_display.connect (on_new_tweet);
            this.tweets.user_display.connect (on_unread_tweets);
            this.mentions.user_display.connect (on_unread_mentions);
            this.dm.user_display.connect (on_unread_dm);
            //

            this.indicator.show ();
        }

        private void on_unread_tweets () {
            this.birdie.switch_timeline ("home");
            this.birdie.activate ();
        }

        private void on_unread_mentions () {
            this.birdie.switch_timeline ("mentions");
            this.birdie.activate ();
        }

        private void on_unread_dm () {
            this.birdie.switch_timeline ("dm");
            this.birdie.activate ();
        }

        private void on_new_tweet () {
            Widgets.TweetDialog dialog = new Widgets.TweetDialog (birdie);
            dialog.show_all ();
        }

        private void on_user_display () {
            birdie.activate ();
            clean_tweets_indicator ();
        }

        private Indicate.Indicator add_indicator (string label) {
            var item = new Indicate.Indicator.with_server (indicator);
            item.set_property_variant ("name", label);
            items.append (item);
            return item;
        }

        public void update_tweets_indicator (int unread) {
            debug ("Updating new tweets indicator with %d new tweets.", unread);
            update_indicator (unread, this.tweets);
        }

        public void update_mentions_indicator (int unread) {
            debug ("Updating new mentions indicator with %d new mentions.", unread);
            update_indicator (unread, this.mentions);
        }

        public void update_dm_indicator (int unread) {
            debug ("Updating new dm indicator with %d new dm.", unread);
            update_indicator (unread, this.dm);
        }

        public void clean_tweets_indicator () {
            clean_indicator (this.tweets);
        }

        public void clean_mentions_indicator () {
            clean_indicator (this.mentions);
        }

        public void clean_dm_indicator () {
            clean_indicator (this.dm);
        }

        private void clean_indicator (Indicate.Indicator item) {
            item.set_property_variant ("count", "0");
            item.set_property_bool ("draw-attention", false);
            item.hide ();
        }

        private void update_indicator (int unread, Indicate.Indicator item) {
            if (unread > 0) {
                //count is in fact a string property
                item.set_property_variant ("count", unread.to_string ());
                item.set_property_bool ("draw-attention", true);
                item.show();
            }
            else
                item.hide();
        }
    #else
        public Indicator (Birdie birdie) {
        }
    #endif
    }
}
