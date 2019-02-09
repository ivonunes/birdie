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

namespace Birdie.Widgets {
    public class MainWindow : Gtk.Window
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

            .titlebar .linked .button, .titlebar .linked .toggle {
                border-radius: 0;
                padding: 12px 10px;
                border-top-width: 0;
                box-shadow: none;
                background: transparent;
                border-left-width: 1px;
                border-right-width: 1px;
            }

            .titlebar .linked .button:checked, .titlebar .linked .toggle:checked {
                box-shadow: inset 0 0 0 1px alpha (#000, 0.05);
                border-left-width: 1px;
                border-right-width: 1px;
            }

            .titlebar .linked .button:not(:checked), .titlebar .linked .toggle:not(:checked) {
                border-color: transparent;
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

        public MainWindow (Gtk.Application application) {
            Object (
                application: application,
                height_request: 575,
                icon_name: "me.ivonunes.birdie",
                resizable: true,
                title: _("Birdie"),
                width_request: 300
            );

            // set smooth scrolling events
            set_events(Gdk.EventMask.SMOOTH_SCROLL_MASK);

            Gdk.Geometry geo = new Gdk.Geometry();
            geo.min_width = 575;
            geo.min_height = 300;
            geo.max_width = 775;
            geo.max_height = 2048;
            this.set_geometry_hints(null, geo, Gdk.WindowHints.MIN_SIZE | Gdk.WindowHints.MAX_SIZE);

            header = new Gtk.HeaderBar ();
            header.set_show_close_button (true);
            this.set_titlebar (header);

            this.delete_event.connect (on_delete_event);

            Granite.Widgets.Utils.set_theming_for_screen (this.get_screen (), ELEMENTARY_STYLESHEET,
                                                          Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        private bool on_delete_event () {
            this.save_window ();
            this.save_state();
            this.destroy();
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
