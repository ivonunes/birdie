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
    public class MenuPopOver : Gtk.Menu {
#if HAVE_GRANITE
        public const string COMPOSITED_INDICATOR = "composited-indicator";

        // used for drawing
        private Gtk.Window menu;
        private Granite.Drawing.BufferSurface buffer;
        private int w = -1;
        private int h = -1;
        private int window_x = -1;
        private int window_y = -1;
        private int window_w = -1;
        private int window_h = -1;
        private int arrow_height = 10;
        private int arrow_width = 20;
        private double x = 10.5;
        private double y = 5.5;
        private int radius = 5;

        private Gtk.Widget widget;

        private const string MENU_STYLESHEET = """
            .menu {
                background-color:@transparent;
                border-color:@transparent;
                -unico-inner-stroke-width: 0;
                background-image:none;
             }
             .popover_bg {
               background-color:#fff;
             }
         """;

        public MenuPopOver () {
            get_style_context ().add_class (COMPOSITED_INDICATOR);
            show ();
            setup_drawing ();
        }

        private void setup_drawing () {
            setup_entry_menu_parent ();

            buffer = new Granite.Drawing.BufferSurface (100, 100);

            this.margin_top = 23;
            this.margin_bottom = 23;

            Granite.Widgets.Utils.set_theming (this, MENU_STYLESHEET, null,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            menu = new Granite.Widgets.PopOver ();

            Granite.Widgets.Utils.set_theming (menu, MENU_STYLESHEET,
                                               Granite.StyleClass.POPOVER_BG,
                                               Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        }

        private void setup_entry_menu_parent () {
            var menu_parent = this.get_parent ();
            menu_parent.app_paintable = true;
            menu_parent.set_visual (Gdk.Screen.get_default ().get_rgba_visual ());

            menu_parent.size_allocate.connect (entry_menu_parent_size_allocate);
            menu_parent.draw.connect (entry_menu_parent_draw_callback);
        }

        private void entry_menu_parent_size_allocate (Gtk.Allocation alloc) {
            this.get_children ().foreach ((c) => {
                // make sure it is always right
                c.margin_left = 10;
                c.margin_right = 9;
            });
        }

        private bool entry_menu_parent_draw_callback (Cairo.Context ctx) {
            var new_w  = this.get_parent ().get_allocated_width ();
            var new_h = this.get_parent ().get_allocated_height ();

            int new_window_x;
            int new_window_y;
            int new_window_w = this.get_toplevel ().get_window ().get_width ();
            int new_window_h = this.get_toplevel ().get_window ().get_height ();

            this.get_toplevel ().get_window ().get_position (out new_window_x, out new_window_y);

            if (new_w != w || new_h != h || new_window_x != window_x || new_window_y != window_y ||
                new_window_w != window_w || new_window_h != window_h) {
                w = new_w;
                h = new_h;

                window_x = new_window_x;
                window_y = new_window_y;
                window_w = new_window_w;
                window_h = new_window_h;

                buffer = new Granite.Drawing.BufferSurface (w, h);
                cairo_popover (w, h);

                var cr = buffer.context;

                // shadow
                cr.set_source_rgba (0, 0, 0, 0.5);
                cr.fill_preserve ();
                buffer.exponential_blur (6);
                cr.clip ();

                // background
                menu.get_style_context ().render_background (cr, 0, 0, w, h);
                cr.reset_clip ();

                // border
                cairo_popover (w, h);
                cr.set_operator (Cairo.Operator.SOURCE);
                cr.set_line_width (1);
                Gdk.cairo_set_source_rgba (cr, menu.get_style_context ().get_border_color (Gtk.StateFlags.NORMAL));
                cr.stroke ();
            }

            // clear surface to transparent
            ctx.set_operator (Cairo.Operator.SOURCE);
            ctx.set_source_rgba (0, 0, 0, 0);
            ctx.paint ();

            // now paint our buffer on
            ctx.set_source_surface (buffer.surface, 0, 0);
            ctx.paint ();

            return false;
        }

        private void cairo_popover (int w, int h) {
            w = w - 20;
            h = h - 20;

            var offs = 30;

            // Get some nice pos for the arrow
            if (widget != null) {
                int p_x;
                int w_x;
                Gtk.Allocation alloc;
                widget.get_window ().get_origin (out p_x, null);
                widget.get_allocation (out alloc);

                this.get_window ().get_origin (out w_x, null);

                offs = (p_x + alloc.x) - w_x + widget.get_allocated_width () / 4;
                if (offs + 50 > (w + 20))
                    offs = (w + 20) - 15 - arrow_width;
                if (offs < 17)
                    offs = 17;
            } else {
                offs = w / 2;
            }

            buffer.context.arc (x + radius, y + arrow_height + radius, radius, Math.PI, Math.PI * 1.5);
            buffer.context.line_to (offs, y + arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, -arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, arrow_height);
            buffer.context.arc (x + w - radius, y + arrow_height + radius, radius, Math.PI * 1.5, Math.PI * 2.0);

            buffer.context.arc (x + w - radius, y + h - radius, radius, 0, Math.PI * 0.5);
            buffer.context.arc (x + radius, y + h - radius, radius, Math.PI * 0.5, Math.PI);

            buffer.context.close_path ();
        }

        public void move_to_widget (Gtk.Widget w) {
            this.widget = w;
        }
#endif
    }
}
