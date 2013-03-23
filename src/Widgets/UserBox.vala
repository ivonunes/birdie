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

        public UserBox () {
            GLib.Object (orientation: Gtk.Orientation.HORIZONTAL);
        }

        public void init (User user, Birdie birdie) {
            this.birdie = birdie;
            this.user = user;

            // tweet box
            this.user_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.pack_start (this.user_box, true, true, 0);

            // avatar alignment
            this.avatar_alignment = new Gtk.Alignment (0,0,0,1);
            this.avatar_alignment.top_padding = 12;
            this.avatar_alignment.right_padding = 6;
            this.avatar_alignment.bottom_padding = 12;
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
            this.content_alignment.top_padding = 12;
            this.content_alignment.right_padding = 6;
            this.content_alignment.bottom_padding = 12;
            this.content_alignment.left_padding = 6;
            this.content_alignment.set_valign (Gtk.Align.CENTER);
            this.user_box.pack_start (this.content_alignment, false, false, 0);

            // content box
            this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.content_box.set_valign (Gtk.Align.CENTER);
            this.content_alignment.add (this.content_box);

            if ("&" in user.screen_name)
                user.screen_name = user.screen_name.replace ("&", "&amp;");
            if ("&" in user.name)
                user.name = user.name.replace ("&", "&amp;");
            if ("&" in user.desc)
                user.desc = user.desc.replace ("&", "&amp;");
            if ("&" in user.location)
                user.location = user.location.replace ("&", "&amp;");

            // user label
            this.username_label = new Gtk.Label (user.screen_name);
            this.username_label.set_halign (Gtk.Align.START);
            this.username_label.margin_bottom = 6;

            string user_url;
            string tweets_txt;

            this.username_label.set_markup ("<span underline='none' color='#000000' font_weight='bold' size='large'>" + user.name + "</span> <span font_weight='light' color='#aaaaaa'>@" + user.screen_name + "</span>\n" + "<span size='small'>" + user.location + "</span>");
            this.content_box.pack_start (this.username_label, false, true, 0);

            // user info

            if (this.birdie.service == 0)
                tweets_txt = _("TWEETS");
            else
                tweets_txt = _("STATUSES");

            string description_txt = user.desc +
                "\n\n<span size='small' color='#666666'>" + tweets_txt +
                " </span><span size='small' font_weight='bold'>" + user.statuses_count.to_string() + "</span>" +
                "<span size='small' color='#666666'> " + _("FOLLOWING") +
                " </span><span size='small' font_weight='bold'>" + user.friends_count.to_string() + "</span>" +
                "<span size='small' color='#666666'> " + _("FOLLOWERS") +
                " </span><span size='small' font_weight='bold'>" + user.followers_count.to_string() + "</span>";

            this.description_label = new Gtk.Label (description_txt);
            this.description_label.set_markup (description_txt);
            this.description_label.set_line_wrap (true);
            this.description_label.set_halign (Gtk.Align.START);
            this.description_label.xalign = 0;
            this.content_box.pack_start (this.description_label, false, true, 0);

            // css
			//Gtk.StyleContext ctx = this.user_box.get_style_context();
			//ctx.add_class("user_box");

            //this.set_size_request (-1, 200);

            this.show_all ();
        }
        
        public void update (User user) {
            this.user = user;
        
            this.avatar_img.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + user.profile_image_file);

            if ("&" in user.screen_name)
                user.screen_name = user.screen_name.replace ("&", "&amp;");
            if ("&" in user.name)
                user.name = user.name.replace ("&", "&amp;");
            if ("&" in user.desc)
                user.desc = user.desc.replace ("&", "&amp;");
            if ("&" in user.location)
                user.location = user.location.replace ("&", "&amp;");

            string user_url;
            string tweets_txt;

            this.username_label.set_markup ("<span underline='none' color='#000000' font_weight='bold' size='large'>" + user.name + "</span> <span font_weight='light' color='#aaaaaa'>@" + user.screen_name + "</span>\n" + "<span size='small'>" + user.location + "</span>");

            // user info

            if (this.birdie.service == 0)
                tweets_txt = _("TWEETS");
            else
                tweets_txt = _("STATUSES");

            string description_txt = user.desc +
                "\n\n<span size='small' color='#666666'>" + tweets_txt +
                " </span><span size='small' font_weight='bold'>" + user.statuses_count.to_string() + "</span>" +
                "<span size='small' color='#666666'> " + _("FOLLOWING") +
                " </span><span size='small' font_weight='bold'>" + user.friends_count.to_string() + "</span>" +
                "<span size='small' color='#666666'> " + _("FOLLOWERS") +
                " </span><span size='small' font_weight='bold'>" + user.followers_count.to_string() + "</span>";

            this.description_label.set_markup (description_txt);
            
            this.show_all ();
        }
    }
}
