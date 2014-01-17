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

    public class NewListDialog : Gtk.Dialog {
	    private Gtk.Entry name_entry;
	    private Gtk.Entry description_entry;
	    private Gtk.Widget create_button;
	    private Birdie birdie;

	    public NewListDialog (Birdie birdie) {
	        this.birdie = birdie;
		    this.title = "New List";
		    this.border_width = 5;
		    set_default_size (350, 100);
		    create_widgets ();
		    connect_signals ();
	    }

	    private void create_widgets () {
		    this.name_entry = new Gtk.Entry ();
		    Gtk.Label name_label = new Gtk.Label.with_mnemonic (_("Name:"));
		    name_label.mnemonic_widget = this.name_entry;

		    this.description_entry = new Gtk.Entry ();
		    Gtk.Label description_label = new Gtk.Label.with_mnemonic (_("Description:"));
		    description_label.mnemonic_widget = this.description_entry; 

		    Gtk.Box hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);
		    hbox.pack_start (name_label, false, true, 0);
		    hbox.pack_start (this.name_entry, true, true, 0);
		    
		    Gtk.Box hbox2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);
		    hbox2.pack_start (description_label, false, true, 0);
		    hbox2.pack_start (this.description_entry, true, true, 0);

		    Gtk.Box content = get_content_area () as Gtk.Box;
		    content.pack_start (hbox, false, true, 0);
		    content.pack_start (hbox2, false, true, 0);
		    content.spacing = 10;

		    add_button (_("Cancel"), Gtk.ResponseType.CLOSE);
		    this.create_button = add_button (_("Create"), Gtk.ResponseType.APPLY);
		    this.create_button.sensitive = false;
	    }

	    private void connect_signals () {
		    this.name_entry.changed.connect (() => {
			    this.create_button.sensitive = (this.name_entry.text != "");
		    });
		    this.response.connect (on_response);
	    }

	    private void on_response (Gtk.Dialog source, int response_id) {
		    switch (response_id) {
		    case Gtk.ResponseType.APPLY:
			    on_create_clicked ();
			    break;
		    case Gtk.ResponseType.CLOSE:
			    destroy ();
			    break;
		    }
	    }

	    private void on_create_clicked () {
	        this.hide ();
		    string name = this.name_entry.text;
		    string description = this.description_entry.text;

		    birdie.api.create_list (name, description);
		    destroy ();
	    }
    }
}
