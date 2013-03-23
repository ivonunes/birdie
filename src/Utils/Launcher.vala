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

    public class Launcher : Object {

        private Unity.LauncherEntry? launcher = null;
        
        Birdie birdie;
        
        public Launcher(Birdie birdie) {
            
            this.birdie = birdie;
            
            launcher = Unity.LauncherEntry.get_for_desktop_id ("birdie.desktop");
            set_count(0);
            
            // construct quicklist
            var ql = new Dbusmenu.Menuitem ();
            var new_tweet = new Dbusmenu.Menuitem ();
            var home = new Dbusmenu.Menuitem ();
            var mentions = new Dbusmenu.Menuitem ();
            var profile = new Dbusmenu.Menuitem ();
            var dm = new Dbusmenu.Menuitem ();

            // new tweet
            new_tweet.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("New Tweet"));
            new_tweet.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (new_tweet);
            launcher.quicklist = ql;
            
            // home timeline
            home.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Tweets"));
            home.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (home);
            launcher.quicklist = ql;
            
            // mentions timeline
            mentions.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Mentions"));
            mentions.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (mentions);
            launcher.quicklist = ql;
            
            // profile timeline
            profile.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Profile"));
            profile.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (profile);
            launcher.quicklist = ql;
            
            // dm timeline
            dm.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Messages"));
            dm.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (dm);
            launcher.quicklist = ql;
                  
            // events connections
            new_tweet.item_activated.connect (() => {
		            this.on_new_tweet ();
		        });
		        
		    home.item_activated.connect (() => {
		            this.on_home ();
		        });
		        
		    mentions.item_activated.connect (() => {
		            this.on_mentions ();
		        });
		        
		    profile.item_activated.connect (() => {
		            this.on_profile ();
		        });
		        
		    dm.item_activated.connect (() => {
		            this.on_dm ();
		        });

        }
        
        private void on_new_tweet() {
            Widgets.TweetDialog dialog = new Widgets.TweetDialog (birdie); 
            dialog.show_all ();
        }
        
        private void on_home () {
            this.birdie.switch_timeline ("home");
            this.birdie.activate ();
        }
        
        private void on_mentions () {
            this.birdie.switch_timeline ("mentions");
            this.birdie.activate ();
        }
        
        private void on_dm () {
            this.birdie.switch_timeline ("dm");
            this.birdie.activate ();
        }
        
        private void on_profile () {
            this.birdie.switch_timeline ("own");
            this.birdie.activate ();
        }
        
        public void set_count (int count) {
            launcher.count = count;
            launcher.count_visible = true;
            
            if (launcher.count == 0) {
                launcher.count_visible = false;
            }
            
            debug("set unity launcher entry count to %s", launcher.count.to_string());
        }
        
        public void clean_launcher_count () {
            launcher.count = 0;
            launcher.count_visible = false;
        }
    }
}
