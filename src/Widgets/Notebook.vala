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

namespace Birdie.Widgets
{
    public class Notebook : Gtk.Box {
        Gtk.Stack stack;
        Gtk.StackSwitcher stack_switcher;
        Gtk.Box stack_switcher_box;

        public Notebook () {
            this.orientation = Gtk.Orientation.VERTICAL;

            this.stack = new Gtk.Stack ();
        	this.stack.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);

            this.stack_switcher = new Gtk.StackSwitcher ();
            this.stack_switcher.set_stack (this.stack);
            this.stack_switcher_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.stack_switcher_box.pack_start (new Gtk.Label(""), true, true, 0);
            this.stack_switcher_box.pack_start (this.stack_switcher, false, false, 0);
            this.stack_switcher_box.pack_start (new Gtk.Label(""), true, true, 0);

            this.pack_start (this.stack_switcher_box, false, false, 10);
            this.pack_start (this.stack);

            this.show_all();
        }

        public void set_tabs (bool show) {
            if (show) {
                this.stack_switcher_box.no_show_all = false;
                this.stack_switcher_box.show_all();
            } else {
                this.stack_switcher_box.no_show_all = true;
                this.stack_switcher_box.hide();
            }
        }

        public void set_border (bool show) {
        }

        public void add_named (Gtk.Widget child, string name) {
            this.stack.add_named (child, name);
        }

        public void add_titled (Gtk.Widget child, string name, string title) {
            this.stack.add_titled (child, name, title);
        }

        public void set_visible_child (Gtk.Widget child) {
            this.stack.set_visible_child (child);
        }

        public void set_visible_child_full (string name, Gtk.StackTransitionType transition) {
            this.stack.set_visible_child_full (name, transition);
        }

        public void set_visible_child_name (string name) {
            this.stack.set_visible_child_name (name);
        }
    }
}
