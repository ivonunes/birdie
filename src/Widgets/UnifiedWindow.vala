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
 * Authored by: Ivo Nunes <ivo@elementaryos.org>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie.Widgets {
    public class UnifiedWindow : Gtk.Window
    {
        private bool hide_on_delete_enabled;
        private bool legacy;
    
        Gtk.Box container;
        Gtk.Toolbar toolbar;
        Gtk.ToolItem label;
     
        const int HEIGHT = 48;
        const int ICON_SIZE = Gtk.IconSize.LARGE_TOOLBAR;
        const string CSS = """
            .title {
                color: #666;
                text-shadow: 0 1 0 white;
            }
            .toolbar {
                padding: 0;
                box-shadow: inset 0 1 0 rgba(255,255,255,0.3);
            }
        """;
        Gtk.CssProvider css;
     
        Gtk.Label _title;
        public new string title {
            get {
                return _title.label;
            }
            set {
                _title.label = value;
            }
        }

        public int opening_x;
        public int opening_y;
        public int window_width;
        public int window_height;
     
        public UnifiedWindow (string title = "", bool legacy = false) {
            this.legacy = legacy;
            this.opening_x = -1;
            this.opening_y = -1;
            this.window_width = -1;
            this.window_height = -1;
            
            css = new Gtk.CssProvider ();
            try {
                if (!legacy)
                    css.load_from_data (CSS, -1);
            } catch (Error e) { warning (e.message); }
     
            toolbar = new Gtk.Toolbar ();
            toolbar.icon_size = ICON_SIZE;
            if (legacy)
                toolbar.get_style_context ().add_class ("primary-toolbar");
            else
                toolbar.get_style_context ().add_class ("titlebar");
            toolbar.get_style_context ().add_provider (css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            
            container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            container.pack_start (toolbar, false);
     
            var close = new Gtk.ToolButton (new Gtk.Image.from_file ("/usr/share/themes/elementary/metacity-1/close.svg"), "Close");
            close.height_request = HEIGHT;
            close.width_request = HEIGHT;
            close.clicked.connect (() => on_delete_event ());
            
            this.hide_on_delete_enabled = false;

            var maximize = new Gtk.ToolButton (new Gtk.Image.from_file ("/usr/share/themes/elementary/metacity-1/maximize.svg"), "Close");
            maximize.height_request = HEIGHT;
            maximize.width_request = HEIGHT;
            maximize.clicked.connect (() => { get_window ().maximize (); });
     
            _title = new Gtk.Label (title);
            _title.override_font (Pango.FontDescription.from_string ("bold"));
            this.title = title;

            if (!legacy)
                toolbar.insert (close, -1);

            if (this.title != "" && !legacy) {
                label = new Gtk.ToolItem ();
                label.add (_title);
                label.set_expand (true);
                label.get_style_context ().add_class ("title");
                label.get_style_context ().add_provider (css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                toolbar.insert (create_separator (), -1);
                toolbar.insert (label, -1);
                toolbar.insert (create_separator (), -1);
                toolbar.insert (maximize, -1);
            }

            if (legacy) {
                this.set_title (title);
                this.delete_event.connect (on_delete_event);
            }
            base.add (container);
        }
        
        private bool on_delete_event () {
            if (this.hide_on_delete_enabled) {
                this.save_window ();
                base.hide_on_delete ();
            } else {
                destroy ();
            }
            base.hide_on_delete ();
            
            return true;
        }
        
        public new void hide_on_delete (bool enable = true) {
            if (enable)
                this.hide_on_delete_enabled = true;
            else
                this.hide_on_delete_enabled = false;
        }
     
        public Gtk.ToolItem create_separator () {
            var sep = new Gtk.ToolItem ();
            sep.height_request = HEIGHT;
            sep.width_request = 1;
            sep.draw.connect ((cr) => {
                cr.move_to (0, 0);
                cr.line_to (0, 60);
                cr.set_line_width (1);
                var grad = new Cairo.Pattern.linear (0, 0, 0, HEIGHT);
                grad.add_color_stop_rgba (0, 0.3, 0.3, 0.3, 0.4);
                grad.add_color_stop_rgba (0.8, 0, 0, 0, 0);
                cr.set_source (grad);
                cr.stroke ();
                return true;
            });
            sep.get_style_context ().add_class ("sep");
            sep.get_style_context ().add_provider (css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
     
            return sep;
        }
     
        public override void add (Gtk.Widget widget) {
            container.pack_start (widget);
        }
            
        public override void remove (Gtk.Widget widget) {
            container.remove (widget);
        }

        public void save_window () {
            this.get_position (out opening_x, out opening_y);
            this.get_size (out window_width, out window_height);
        }

        public void restore_window () {
            if (this.opening_x > 0 && this.opening_y > 0 && this.window_width > 0 && this.window_height > 0) {
                this.move (this.opening_x, this.opening_y);
                this.set_default_size (this.window_width, this.window_height);
            }
        }
            
        public override void show () {
            base.show ();
            if (!legacy)
                get_window ().set_decorations (Gdk.WMDecoration.BORDER);
            this.restore_window ();
        }
            
        public void add_bar (Gtk.ToolItem item, bool after_title = false) {
            if (this.title != "" && !legacy) {
                toolbar.insert (item, after_title ? toolbar.get_n_items () - 2 : toolbar.get_item_index (label));
            } else {
                toolbar.insert (item, -1);
            }
        }
            
        public void remove_bar (Gtk.ToolItem item) {
            toolbar.remove (item);
        }
    }
}
