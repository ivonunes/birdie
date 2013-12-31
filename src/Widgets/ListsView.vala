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

namespace Birdie.Widgets {
    public class ListsView : Gtk.ListBox {
        private bool first;

        public ListsView () {
            GLib.Object (valign: Gtk.Align.START);
            this.set_selection_mode (Gtk.SelectionMode.NONE);

            first = true;
        }

        public void append (TwitterList list, Birdie birdie) {
            if (first) {
                first = false;
            } else {
                this.prepend (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
            }

            this.prepend (new ListBox (list, birdie));
            this.show_all ();
        }

        public void clear () {
            first = true;
        }
    }
}
