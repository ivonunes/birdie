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

namespace Birdie.Widgets
{
    public class AlertDialog : Object {
        private Gtk.MessageDialog dialog;

        public AlertDialog (Gtk.Window? parent,
                Gtk.MessageType message_type, string primary,
                string? ok_button, string? cancel_button) {
            dialog = new Gtk.MessageDialog(parent,
                Gtk.DialogFlags.DESTROY_WITH_PARENT, message_type,
                Gtk.ButtonsType.NONE, "");

            dialog.text = primary;
            dialog.add_button (cancel_button, Gtk.ResponseType.CANCEL);
            dialog.add_button (ok_button, Gtk.ResponseType.OK);
        }

        public Gtk.Box get_message_area () {
            return (Gtk.Box) dialog.get_message_area();
        }

        // Runs dialog, destroys it, and returns selected response
        public Gtk.ResponseType run () {
            Gtk.ResponseType response = (Gtk.ResponseType) dialog.run();
            dialog.destroy();
            return response;
        }
    }

    class ConfirmationDialog : AlertDialog {
        public ConfirmationDialog (Gtk.Window? parent,
                string primary, string? ok_button) {
            base (parent, Gtk.MessageType.WARNING, primary,
                ok_button, _("Cancel"));
        }
    }

    class ErrorDialog : AlertDialog {
        public ErrorDialog (Gtk.Window? parent,
                string primary, string? secondary) {
            base (parent, Gtk.MessageType.ERROR, primary, _("OK"), null);
        }
    }

#if HAVE_GRANITE
    public class LightWindow : Granite.Widgets.LightWindow {
        bool drag;

        public LightWindow (bool drag = true) {
            this.drag = drag;
        }

        public override bool button_press_event (Gdk.EventButton e) {
            if (drag)
                return base.button_press_event (e);
            else
                return false;
        }
    }
#else
    public class LightWindow : Gtk.Window {
        Gtk.Box box;

        public LightWindow (bool drag = true) {
            set_title (_("Preview"));
            set_resizable (false);

            this.box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            base.add (this.box);
        }

        public new void add (Gtk.Widget w) {
            this.box.pack_start (w, true, true);
        }

        public new void remove (Gtk.Widget w) {
            this.box.remove (w);
        }
    }
#endif
}
