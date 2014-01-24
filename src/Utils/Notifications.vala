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
    private static Canberra.Context? sound_context = null;
    private List<string> caps;
    private Notify.Notification notification;
    private string switch_timeline;
    private Birdie birdie_app;

    public int notify (string username, string avatar, string message, string timeline, Birdie birdie, bool dm = false) {

        switch_timeline = timeline;
        birdie_app = birdie;
        string notification_txt;
        string avatar_img;
        string avatar_path;

        Notify.init ("Birdie");

        if (!Notify.is_initted()) {
            if (!Notify.init(GLib.Environment.get_application_name()))
                critical("Failed to initialize libnotify.");
        }

        caps = Notify.get_server_caps();

        notification_txt = Utils.remove_html_tags (message);
        notification_txt = Utils.escape_markup (notification_txt);

        avatar_path = Environment.get_home_dir () + "/.cache/birdie/" + avatar;

        var file = File.new_for_path (avatar_path);

        if (avatar == "" || avatar == null || !file.query_exists ())
            avatar_img = "birdie";
        else
            avatar_img = avatar_path;

        try {
            notification = new Notify.Notification (username, notification_txt, avatar_img);
            notification.set_hint_string ("desktop-entry", "birdie");

            if (!dm) {
                notification.set_timeout (8000);
            } else {
                notification.set_timeout (0);
                notification.set_urgency (Notify.Urgency.CRITICAL);
            }


            if (caps.find_custom ("actions", GLib.strcmp) != null)
                notification.add_action ("view", _("View"), (notification, action) => {
                    birdie_app.switch_timeline (switch_timeline);
                    birdie_app.activate ();
                });

            notification.show ();
        } catch (Error e) {
            error ("Failed to show notification: %s", e.message);
        }

        // play sound
        init_sound ();
        sound_context.play (0, Canberra.PROP_EVENT_ID, "message");
        return 0;
    }

    private static void init_sound () {
        if (sound_context == null)
            Canberra.Context.create (out sound_context);
    }
}