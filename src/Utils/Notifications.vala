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
    private static Canberra.Context? sound_context = null;
    //private unowned List<string> caps;

    public int notify (string username, string message) {

        //caps = Notify.get_server_caps();
    
        Notify.Notification notification = (Notify.Notification) GLib.Object.new(
            typeof (Notify.Notification),
            "icon-name", "birdie",
            "summary", username);
        Notify.init (GLib.Environment.get_application_name());
        notification.set_hint_string ("desktop-entry", "birdie");
        notification.set ("body", Utils.remove_html_tags (message));
        //if (caps.find_custom ("actions", GLib.strcmp) != null)
            //notification.add_action ("default", _("Open"), on_default_action);
        try {
            notification.show ();
        } catch (GLib.Error error) {
            warning ("Failed to show notification: %s", error.message);
        }

        // play sound
        Canberra.Context.create (out sound_context);
        sound_context.play (0, Canberra.PROP_EVENT_ID, "message");
        
        return 0;   
    }

    //private void on_default_action (Notify.Notification notification, string action) {
        
    //}
}
