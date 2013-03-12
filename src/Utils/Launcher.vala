namespace Birdie.Utils {

    public class Launcher : Object {

        private Unity.LauncherEntry? launcher = null;
        
        Birdie birdie;
        
        public Launcher(Birdie birdie) {
            
            this.birdie = birdie;
            
            launcher = Unity.LauncherEntry.get_for_desktop_id ("birdie.desktop");
            set_count(0);
            
            /*
            // construct quicklist
            var ql = new Dbusmenu.Menuitem ();
            var new_tweet = new Dbusmenu.Menuitem ();
            var home = new Dbusmenu.Menuitem ();
            var mentions = new Dbusmenu.Menuitem ();
            var dm = new Dbusmenu.Menuitem ();
            
            home.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Home"));
            home.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (home);
            mentions.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Mentions"));
            mentions.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (mentions);
            dm.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("Messages"));
            dm.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (dm);
            new_tweet.property_set (Dbusmenu.MENUITEM_PROP_LABEL, _("New Tweet"));
            new_tweet.property_set_bool (Dbusmenu.MENUITEM_PROP_VISIBLE, true);
            ql.child_append (new_tweet);
            launcher.quicklist = ql;   
            
            */        
        }
        
        private void set_count (int count) {
            launcher.count = count;
            if (launcher.count > 0) {
                launcher.count_visible = true;
            }
            debug("set unity launcher entry count to %s", launcher.count.to_string());
        }
        
        public void update_launcher_count (int count) {
            set_count(count);
        }
        
        public void clean_launcher_count (int count) {
            launcher.count = launcher.count-count;
            if (launcher.count == 0) {
                launcher.count_visible = false;
            }
        }
    }
}
