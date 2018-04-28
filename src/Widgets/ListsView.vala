// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Amuza Limited
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@amuza.uk>
 *              Vasco Nunes <vasco@amuza.uk>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Widgets {
    public class ListsView : Gtk.ListBox {

        public AddButton add_button;

        public ListsView (Birdie birdie) {
            GLib.Object (valign: Gtk.Align.START);
            this.set_selection_mode (Gtk.SelectionMode.NONE);

            this.add_button = new AddButton ();
            this.add_button.button.clicked.connect (() => {
                NewListDialog dialog = new NewListDialog (birdie);
		        dialog.destroy.connect (Gtk.main_quit);
		        dialog.show_all ();
            });
            this.prepend (this.add_button.button);
        }

        public void append (TwitterList list, Birdie birdie) {
            this.prepend (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            this.prepend (new ListBox (list, birdie));
            this.show_all ();
        }

        public void clear () {
            foreach (Gtk.Widget w in this.get_children()) {
                if (((Gtk.ListBoxRow) w).get_child () != this.add_button.button && (w is Gtk.ListBoxRow)) {
                    Idle.add (() => {
                        base.remove (w);
                        return false;
                    });
                }
            }
        }

        public new void remove (TwitterList list) {
            bool separator_next = false;

            this.get_children ().foreach ((row) => {
                if (row is Gtk.ListBoxRow) {
                    var box = ((Gtk.ListBoxRow) row).get_child ();

                    if ((box is ListBox)) {
                        if (((ListBox) box).list == list) {
                            separator_next = true;

                            Idle.add( () => {
                                base.remove (row);
                                return false;
                            });
                        }
                    } else if (separator_next) {
                        base.remove (row);
                        separator_next = false;
                    }
                }
            });
        }
    }
}
