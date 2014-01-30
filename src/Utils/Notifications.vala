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

    public class Notification {

        private Canberra.Context sound_context;
        private List<string> caps;
        private Notify.Notification notification;
        private string switch_timeline;
        private Birdie birdie_app;

        public void init () {
            Notify.init ("Birdie");
            Canberra.Context.create (out this.sound_context);
        }

        public void notify (Birdie birdie,
                            string header,
                            string? message = "",
                            string? timeline = "home",
                            bool? dm = false,
                            string? avatar = null) {

            this.switch_timeline = timeline;
            this.birdie_app = birdie;
            string notification_txt;

            this.caps = Notify.get_server_caps ();

            notification_txt = Utils.remove_html_tags (message);
            notification_txt = Utils.escape_markup (notification_txt);

            this.notification = new Notify.Notification (header, notification_txt, avatar ?? "birdie");
            this.notification.set_hint_string ("desktop-entry", "birdie");
            this.notification.set_urgency (Notify.Urgency.NORMAL);

            if (dm) {
                this.notification.set_timeout (0);
                this.notification.set_urgency (Notify.Urgency.CRITICAL);
            }

            if (this.caps.find_custom ("actions", GLib.strcmp) != null)
                this.notification.add_action ("default", _("View"), (notification, action) => {
                    this.birdie_app.switch_timeline (this.switch_timeline);
                    this.birdie_app.activate ();
                });

            try {
                notification.show ();
            } catch (GLib.Error e) {
                warning ("Failed to show notification: %s", e.message);
            }

            // play sound
            this.sound_context.play (0, Canberra.PROP_EVENT_ID, "message");
        }

        public void uninit() {
            Notify.uninit();
        }
    }
}