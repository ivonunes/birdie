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

        private Notify.Notification notification;
        private Birdie birdie_app;

        public void init () {
            Notify.init ("Birdie");
        }

        public void notify (Birdie birdie,
                            string header,
                            string? message = "",
                            string? timeline = "home",
                            bool? dm = false,
                            string? avatar = null) {

            this.birdie_app = birdie;

            string notification_txt;
            string avatar_path;

            notification_txt = Utils.remove_html_tags (message);
            notification_txt = Utils.escape_markup (notification_txt);

            if (avatar != "" && avatar != null) {
                var file = File.new_for_path (avatar);

                if (file.query_exists ())
                    avatar_path = avatar;
                else
                    avatar_path = "birdie";
            } else {
                avatar_path = "birdie";
            }

            this.notification = new Notify.Notification (header, notification_txt, avatar_path);
            this.notification.set_hint_string ("desktop-entry", "birdie");
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
        }

        public void uninit() {
            Notify.uninit();
        }
    }
}