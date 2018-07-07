// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Ivo Nunes
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivonunes@me.com>
 *              Vasco Nunes <vasco.m.nunes@me.com>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Utils {

    public class Notification {

        private Notify.Notification notification;
        private Birdie birdie_app;
        private static Canberra.Context? sound_context = null;
        private List<string> caps;

        public void init () {
            Notify.init ("Birdie");
            init_sound ();
            caps = Notify.get_server_caps ();
        }

        public void notify (Birdie birdie,
                            string header,
                            string? message = "",
                            string? timeline = "home",
                            bool? dm = false,
                            string? avatar = null) {

            this.birdie_app = birdie;

            string notification_txt;

            notification_txt = Utils.remove_html_tags (message);
            notification_txt = Utils.escape_markup (notification_txt);

            this.notification = new Notify.Notification (header, notification_txt, "me.ivonunes.birdie");
            this.notification.set_hint_string ("desktop-entry", "me.ivonunes.birdie");
            this.notification.set_urgency (Notify.Urgency.NORMAL);

            if (dm) {
                this.notification.set_timeout (0);
                this.notification.set_urgency (Notify.Urgency.CRITICAL);
            }

            this.notification.add_action ("view", _("View"), (notification, action) => {
                this.birdie_app.switch_timeline (timeline);
                this.birdie_app.activate ();
            });

            try {
                notification.show ();
            } catch (GLib.Error e) {
                warning ("Failed to show notification: %s", e.message);
            }

            if (caps.find ("message") != null)
                this.notification.set_hint_string ("sound-name", "message");
            else
                play_sound ("message");
        }

        private static void init_sound() {
            if (sound_context == null)
                Canberra.Context.create (out sound_context);
        }

        public static void play_sound(string sound) {
            init_sound ();
            sound_context.play (0, Canberra.PROP_EVENT_ID, sound);
        }

        public void uninit() {
            Notify.uninit();
        }
    }
}
