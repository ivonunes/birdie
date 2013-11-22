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
    private List<string> caps;
    private Notify.Notification notification;
    private string switch_timeline;
    private Birdie birdie_app;

    public int notify (string username, string message, string timeline, Birdie birdie) {

        switch_timeline = timeline;
        birdie_app = birdie;
        string notification_txt;

        if (!Notify.is_initted()) {
            if (!Notify.init(GLib.Environment.get_application_name()))
                critical("Failed to initialize libnotify.");
        }

        init_sound ();

        caps = Notify.get_server_caps();

        notification = (Notify.Notification) GLib.Object.new(
            typeof (Notify.Notification),
            "icon-name", "birdie",
            "summary", username);

        notification.set_hint_string ("desktop-entry", "birdie");
        
        if (caps.find_custom ("actions", GLib.strcmp) != null)
            notification.add_action ("default", _("View"), on_default_action);
        
        notification_txt = Utils.remove_html_tags (message);
        notification_txt = Utils.escape_markup (notification_txt);
        notification.set ("body", notification_txt);

        try {
            notification.show ();
        } catch (GLib.Error error) {
            warning ("Failed to show notification: %s", error.message);
        }

        // play sound
        sound_context.play (0, Canberra.PROP_EVENT_ID, "message");
        
        return 0;   
    }

    private static void init_sound () {
        if (sound_context == null)
            Canberra.Context.create (out sound_context);
    }

    private void on_default_action (Notify.Notification notification, string action) {
        birdie_app.switch_timeline (switch_timeline);
        birdie_app.activate ();
    }
}
