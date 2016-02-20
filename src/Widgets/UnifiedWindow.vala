// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2016 Birdie Developers (http://birdieapp.github.io)
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
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Widgets {
    public class UnifiedWindow : Gtk.ApplicationWindow
    {

        public signal void save_state();
        public int opening_x;
        public int opening_y;
        public int window_width;
        public int window_height;

        public Gtk.HeaderBar header;
        public Gtk.Box box;

        private const string ELEMENTARY_STYLESHEET = """

            @define-color colorPrimary #55ACEE;
            .titlebar {
                padding: 0 6px;
            }

            .titlebar .linked .button {
                border-radius: 0;
                padding: 12px 10px;
                border-top-width: 0;
                box-shadow: none;
            }

            .titlebar .linked .button:checked {
                 box-shadow: inset 0 0 0 1px alpha (#000, 0.05);
             }

            .favorite-pink {
                color: #E32550;
            }

            .favorite-grey {
                color: #B0B0B0;
            }

            .tweet-entry {
                background: white;
                border-style: solid;
                border-width: 0.25px;
            }

             .white-box {
                background: white;
             }
         """;

        public UnifiedWindow () {
            this.opening_x = -1;
            this.opening_y = -1;
            this.window_width = -1;
            this.window_height = -1;

            // set smooth scrolling events
            set_events(Gdk.EventMask.SMOOTH_SCROLL_MASK);

            this.delete_event.connect (on_delete_event);

            // Set up geometry
            Gdk.Geometry geo = new Gdk.Geometry();
            geo.min_width = 575;
            geo.min_height = 300;
            geo.max_width = 775;
            geo.max_height = 2048;

            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);

            header = new Gtk.HeaderBar ();

            header.set_show_close_button (true);
            this.set_titlebar (header);

            Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), ELEMENTARY_STYLESHEET,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            this.set_title ("Birdie");
            this.set_default_size(575, 300);
        }

        private bool on_delete_event () {
            this.save_window ();
            this.save_state();
            base.hide_on_delete ();
            return true;
        }

        public void save_window () {
            this.get_position (out opening_x, out opening_y);
            this.get_size (out window_width, out window_height);
        }

        public void restore_window () {
            if (this.opening_x > 0 && this.opening_y > 0 && this.window_width > 0 && this.window_height > 0) {
                this.move (this.opening_x, this.opening_y);
                this.resize (this.window_width, this.window_height);
            }
        }

        public override void add (Gtk.Widget w) {
            base.add (w);
        }

        public override void show () {
            base.show ();
            this.restore_window ();
        }
    }
}
