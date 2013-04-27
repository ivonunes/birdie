// Testing brand new popovers

namespace Birdie.Widgets
{
    public class MenuPopOver : Gtk.Menu {
        public const string COMPOSITED_INDICATOR = "composited-indicator";

        // used for drawing
        private Gtk.Window menu;
        private Granite.Drawing.BufferSurface buffer;
        private int w = -1;
        private int h = -1;
        private int arrow_height = 10;
        private int arrow_width = 20;
        private double x = 10.5;
        private double y = 10.5;
        private int radius = 5;

        private Gtk.Box box;

        private const string MENU_STYLESHEET = """
            .menu {
                background-color:@transparent;
                border-color:@transparent;
                -unico-inner-stroke-width: 0;
             }
             .popover_bg {
               background-color:#fff;
             }
         """;

        public MenuPopOver () {
            box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            box.set_homogeneous (false);
            box.spacing = 2;

            add (box);
            box.show ();
            
            get_style_context ().add_class (COMPOSITED_INDICATOR);

            // Enable scrolling events
            add_events (Gdk.EventMask.SCROLL_MASK);

            //set_widget (WidgetSlot.IMAGE, image);

            show ();

            setup_drawing ();
        }

        private void setup_drawing () {
            setup_entry_menu_parent ();

            buffer = new Granite.Drawing.BufferSurface (100, 100);

            this.margin_top = 28;
            this.margin_bottom = 18;

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
            /* this.margin_left = 10;
               this.margin_right = 9;
               FIXME => This is what we want to get, but to solve spacing issues we do this: */

            this.get_children ().foreach ((c) => {
                // make sure it is always right
                c.margin_left = 10;
                c.margin_right = 9;
            });
        }

        private bool entry_menu_parent_draw_callback (Cairo.Context ctx) {
            var new_w  = this.get_parent ().get_allocated_width ();
            var new_h = this.get_parent ().get_allocated_height ();

            if (new_w != w || new_h != h) {
                w = new_w;
                h = new_h;

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

            // Get some nice pos for the arrow
            var offs = 30;
            int p_x;
            int w_x;
            Gtk.Allocation alloc;
            this.get_window ().get_origin (out p_x, null);
            this.get_allocation (out alloc);

            this.get_window ().get_origin (out w_x, null);

            offs = (p_x + alloc.x) - w_x + this.get_allocated_width () / 4;
            if (offs + 50 > (w + 20))
                offs = (w + 20) - 15 - arrow_width;
            if (offs < 17)
                offs = 17;

            buffer.context.arc (x + radius, y + arrow_height + radius, radius, Math.PI, Math.PI * 1.5);
            buffer.context.line_to (offs, y + arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, -arrow_height);
            buffer.context.rel_line_to (arrow_width / 2.0, arrow_height);
            buffer.context.arc (x + w - radius, y + arrow_height + radius, radius, Math.PI * 1.5, Math.PI * 2.0);

            buffer.context.arc (x + w - radius, y + h - radius, radius, 0, Math.PI * 0.5);
            buffer.context.arc (x + radius, y + h - radius, radius, Math.PI * 0.5, Math.PI);
            
            buffer.context.close_path ();
        }

        public override bool scroll_event (Gdk.EventScroll event) {
            /*var direction = Indicator.ScrollDirection.UP;
            double delta = 0;

            switch (event.direction) {
                case Gdk.ScrollDirection.UP:
                    delta = event.delta_y;
                    direction = Indicator.ScrollDirection.UP;
                    break;
                case Gdk.ScrollDirection.DOWN:
                    delta = event.delta_y;
                    direction = Indicator.ScrollDirection.DOWN;
                    break;
                case Gdk.ScrollDirection.LEFT:
                    delta = event.delta_x;
                    direction = Indicator.ScrollDirection.LEFT;
                    break;
                case Gdk.ScrollDirection.RIGHT:
                    delta = event.delta_x;
                    direction = Indicator.ScrollDirection.RIGHT;
                    break;
                default:
                    break;
            }

            entry.parent_object.entry_scrolled (entry, (uint) delta, direction);*/

            return false;
        }

        public void set_widget (/*WidgetSlot slot,*/ Gtk.Widget widget) {
            /*Gtk.Widget old_widget;

            if (slot == WidgetSlot.LABEL)
                old_widget = the_label;
            else if (slot == WidgetSlot.IMAGE)
                old_widget = the_image;
            else
                assert_not_reached ();

            if (old_widget != null) {
                box.remove (old_widget);
                old_widget.get_style_context ().remove_class (StyleClass.COMPOSITED_INDICATOR);
            }

            widget.get_style_context ().add_class (StyleClass.COMPOSITED_INDICATOR);

            if (slot == WidgetSlot.LABEL) {
                the_label = widget;
                box.pack_end (the_label, false, false, 0);
            } else if (slot == WidgetSlot.IMAGE) {
                the_image = widget;
                box.pack_start (the_image, false, false, 0);
            } else {
                assert_not_reached ();
            }*/
        }
    }
}
