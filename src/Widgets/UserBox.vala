namespace Birdie.Widgets {

    public class UserBox : Gtk.Box {

        public User user;
        public Birdie birdie;

        private Gtk.Box user_box;
        private Gtk.Alignment avatar_alignment;
        private Gtk.Image avatar_img;
        private Gtk.Alignment content_alignment;
        private Gtk.Box content_box;
        private Gtk.Label username_label;
        private Gtk.Label description_label;
        private Gtk.Label info_label;

        public UserBox (User user, Birdie birdie) {

            GLib.Object (orientation: Gtk.Orientation.HORIZONTAL);

            this.birdie = birdie;
            this.user = user;

            // tweet box
            this.user_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.pack_start (this.user_box, true, true, 0);

            // avatar alignment
            this.avatar_alignment = new Gtk.Alignment (0,0,0,1);
            this.avatar_alignment.top_padding = 0;
            this.avatar_alignment.right_padding = 6;
            this.avatar_alignment.bottom_padding = 0;
            this.avatar_alignment.left_padding = 12;
            this.user_box.pack_start (this.avatar_alignment, false, true, 0);

            // avatar image
            this.avatar_img = new Gtk.Image ();
            this.avatar_img.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + user.profile_image_file);
            this.avatar_img.set_halign (Gtk.Align.START);
            this.avatar_img.set_valign (Gtk.Align.CENTER);
            this.avatar_alignment.add (this.avatar_img);

            // content alignment
            this.content_alignment = new Gtk.Alignment (0,0,0,1);
            this.content_alignment.top_padding = 0;
            this.content_alignment.right_padding = 6;
            this.content_alignment.bottom_padding = 0;
            this.content_alignment.left_padding = 6;
            this.content_alignment.set_valign (Gtk.Align.CENTER);
            this.user_box.pack_start (this.content_alignment, false, false, 0);

            // content box
            this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.content_box.set_valign (Gtk.Align.CENTER);
            this.content_alignment.add (this.content_box);

            if ("&" in user.screen_name)
                user.screen_name = user.screen_name.replace ("&", "&amp;");

            // user label
            this.username_label = new Gtk.Label (user.screen_name);
            this.username_label.set_halign (Gtk.Align.START);
            this.username_label.margin_bottom = 6;

            string user_url;
            if (birdie.service == 0)
                user_url = "https://twitter.com/";
            else
                user_url = "https://identi.ca/";
            this.username_label.set_markup ("<span underline='none' color='#000000' font_weight='bold' size='large'><a href='" + user_url + user.screen_name + "'>" + user.screen_name + "</a></span> <span font_weight='light' color='#aaaaaa'>@" + user.screen_name + "</span>");
            this.content_box.pack_start (this.username_label, false, true, 0);

            /*  // tweet
            this.description_label = new Gtk.Label (user.description);
            this.description_label.set_markup (user.description);
            this.description_label.set_selectable (true);
            this.description_label.set_line_wrap (true);
            this.description_label.set_halign (Gtk.Align.START);
            this.description_label.xalign = 0;
            this.content_box.pack_start (this.description_label, false, true, 0);

            // css
			Gtk.StyleContext ctx = this.description_label.get_style_context();
			ctx.add_class("tweet");
			//
 */
            //this.set_size_request (-1, 300);
        }

        public void set_selectable (bool select) {
            //this.description_label.set_selectable (select);
        }
    }
}
