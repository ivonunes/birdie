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
 * Authored by: Ivo Nunes <ivoavnunes@gmail.com>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie.Utils {

    public class Indicator : GLib.Object {
#if HAVE_LIBMESSAGINGMENU
        Birdie birdie;
        private MessagingMenu.App? app = null;

        public signal void application_activated(uint32 timestamp);
        public signal void tweet_activated(uint32 timestamp);

        public Indicator (Birdie birdie) {
            this.birdie = birdie;

            app = new MessagingMenu.App("birdie.desktop");
            app.register();
            app.activate_source.connect(on_activate_source);

            debug("Registered messaging-menu");
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
                    clean_tweets_indicator ();
                    break;
                case "mentions":
                    this.birdie.switch_timeline ("mentions");
                    this.birdie.activate ();
                    clean_mentions_indicator ();
                    break;
                case "dm":
                    this.birdie.switch_timeline ("dm");
                    this.birdie.activate ();
                    clean_dm_indicator ();
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
                app.remove_source("tweets");
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
                app.remove_source("mentions");
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
                app.remove_source("dm");
        }

        public void update_new_tweet_indicator() {
            if (!app.has_source("newtweet"))
                app.append_source_with_count("newtweet", null,
                    _("New Tweet"), 0);
        }

        public void clean_tweets_indicator () {
            if (app.has_source("tweets"))
                app.remove_source ("tweets");
        }

        public void clean_mentions_indicator () {
            if (app.has_source("mentions"))
                app.remove_source ("mentions");
        }

        public void clean_dm_indicator () {
            if (app.has_source("mentions"))
                app.remove_source ("mentions");
        }
    #else
        public Indicator (Birdie birdie) {
        }
    #endif
    }
}
