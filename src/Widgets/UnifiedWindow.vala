namespace Birdie.Widgets {
    public class UnifiedWindow : Gtk.Window
    {
        private bool hide_on_delete_enabled;
    
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
     
        public UnifiedWindow (string title = "") {
            css = new Gtk.CssProvider ();
            try {
                css.load_from_data (CSS, -1);
            } catch (Error e) { warning (e.message); }
     
            toolbar = new Gtk.Toolbar ();
            toolbar.icon_size = ICON_SIZE;
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
     
            toolbar.insert (close, -1);

            if (this.title != "") {
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
     
            base.add (container);
        }
        
        private bool on_delete_event () {
            if (this.hide_on_delete_enabled)
                base.hide_on_delete ();
            else
                destroy ();
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
            
        public override void show () {
            base.show ();
            get_window ().set_decorations (Gdk.WMDecoration.BORDER);
        }
            
        public void add_bar (Gtk.ToolItem item, bool after_title = false) {
            if (this.title != "") {
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
