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

            .account-box {
                background-color: #292f33;
            }

            .account-box .button {
                color: white;
            }

            BirdieWidgetsConversationsList .avatar,
            BirdieWidgetsTweetList .avatar {
                border:none;
                box-shadow: inset 0 0 0 1px alpha(#000, 0.15),
                            0 1px 0 0 alpha( #fff, 0.45);
            }

            .titlebar {
                padding: 0 6px;
                box-shadow: inset 0 0 0 1px alpha (#fff, 0.20),
                inset 0 1px 0 0 alpha (#fff, 0.30);
            }

            .titlebar .button {
                border-radius: 0;
                padding: 11px 10px;
                border-width: 0 1px 0 1px;
            }

            .titlebar .linked .button,
            .titlebar .linked button {
                border-right-width:0px;
            }
            
            .titlebar .linked .button:last-child,
            .titlebar .linked button:last-child {
                border-right-width:1px;
            }
            

            .titlebar .button.image-button {
                border-radius: 3px;
                padding: 0;
            }

            .titlebar .button:active:backdrop {
                border-color: #4182aa;
                background-image: none;
                background-color: alpha (#000, 0.01);
                border-color: alpha (#000, 0.15);
                box-shadow: inset 0 0 0 1px alpha (#000, 0.05);
            }

            .titlebar .titlebutton {
                background: none;
                padding: 3px;

                border-radius: 3px;
                border-width: 1px;
                border-color: transparent;
                border-style: solid;
                border-image: none;
            }

            .icon-grey {
                color: #b8b8b8;
            }

            .favorite-pink {
                color: #e81c4f;
            }

            .retweet-green {
                color: #19cf86;
            }

            .icon-blue {
                color: #009DB0;
            }

            .tweet-entry {
                background-color: #fff;

                border: 1px solid @border_color;
                border-radius: 2.5px;

                box-shadow: inset 0 1px 0 0 alpha (@inset_dark_color, 0.7),
                            inset 0 0 0 1px alpha (@inset_dark_color, 0.3),
                            0 1px 0 0 alpha (@bg_highlight_color, 0.30);

                color: @text_color;

                padding: 4px;
            }

            .tweet-entry:selected {
                color: #fff;
                background: #55ACEE;
            }

            .white-box {
                background: white;
            }""";

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
