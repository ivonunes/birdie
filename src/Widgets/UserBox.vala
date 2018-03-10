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

    public class UserBox : Gtk.Box {

        public User user;
        public Birdie birdie;

        private Gtk.Box user_box;
        private Gtk.Box buttons_box;
        private Gtk.Box avatar_box;

        private Granite.Widgets.Avatar avatar;

        private Gtk.Image verified_img;
        private Gtk.Label username_label;
        private Gtk.Button follow_button;
        private Gtk.Button unfollow_button;
        private Gtk.Button block_button;
        private Gtk.Button unblock_button;
        private Gtk.Button lists_button;

        private string description_txt = "";

        public UserBox () {
            GLib.Object (orientation: Gtk.Orientation.HORIZONTAL);
        }

        public void init (User user, Birdie birdie) {
            this.birdie = birdie;
            this.user = user;
            this.margin_bottom = 12;

            // tweet box
            this.user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.pack_start (this.user_box, true, true, 0);

            // avatar image
            this.avatar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.avatar = new Granite.Widgets.Avatar.with_default_icon (50);
            this.avatar.set_halign (Gtk.Align.CENTER);
            this.avatar.set_valign (Gtk.Align.START);
            this.avatar.margin_top = 12;
            this.avatar_box.pack_start (this.avatar, true, true, 0);
            this.user_box.pack_start (this.avatar_box, true, true, 0);

            string tweets_txt = _("TWEETS");

            description_txt = user.desc +
                "\n\n<span size='small' color='#444444'>" + tweets_txt +
                " </span><span size='small' font_weight='bold'>" + user.statuses_count.to_string() + "</span>" +
                " | <span size='small' color='#444444'> " + _("FOLLOWING") +
                " </span><span size='small' font_weight='bold'>" + user.friends_count.to_string() + "</span>" +
                " | <span size='small' color='#444444'> " + _("FOLLOWERS") +
                " </span><span size='small' font_weight='bold'>" + user.followers_count.to_string() + "</span>";

            description_txt = description_txt.chomp ();

            string txt = "<span underline='none' font_weight='bold' size='x-large'>" +
                user.name.chomp () + "</span> <span font_weight='light' color='#444444' size='small'>\n@" + user.screen_name + "</span>";

            if (user.location != "")
                txt = txt +  " | <span size='small'>" + user.location + "</span>";

            if (user.website != "")
                txt = txt +  " | <span size='small'><a href='http://" + user.website + "'>" + user.website + "</a></span>";

            if (description_txt != "")
                txt = txt +  "\n\n<span size='small'>" + description_txt + "</span>";

            // user label
            this.username_label = new Gtk.Label (user.screen_name);
            this.username_label.set_halign (Gtk.Align.CENTER);
            this.username_label.set_valign (Gtk.Align.CENTER);

            // this.verified_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.verified_img = new Gtk.Image ();
            this.verified_img.set_from_icon_name ("twitter-verified", Gtk.IconSize.BUTTON);
            this.verified_img.set_halign (Gtk.Align.CENTER);
            this.verified_img.set_valign (Gtk.Align.CENTER);
            this.verified_img.set_no_show_all (true);
            this.user_box.pack_start (this.verified_img, false, true, 0);
            this.username_label.set_markup (txt);
            this.username_label.set_halign (Gtk.Align.CENTER);
            this.username_label.set_justify (Gtk.Justification.CENTER);
            this.user_box.pack_start (this.username_label, false, true, 0);

            this.username_label.set_line_wrap (true);
            this.user_box.margin_left = 12;
            this.user_box.margin_right = 12;

            // buttons box
            this.buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
            this.buttons_box.set_valign (Gtk.Align.CENTER);
            this.buttons_box.set_halign (Gtk.Align.CENTER);
            this.user_box.pack_start (this.buttons_box, true, true, 0);

            // follow button
            this.follow_button = new Gtk.Button.with_label (_("Follow"));
            this.follow_button.set_halign (Gtk.Align.END);
            this.follow_button.set_tooltip_text (_("Follow user"));
            this.buttons_box.pack_start (this.follow_button, false, true, 0);

            this.follow_button.clicked.connect (() => {
                new Thread<void*> (null, this.follow_thread);
            });

            // unfollow button
            this.unfollow_button = new Gtk.Button.with_label (_("Unfollow"));
            this.unfollow_button.set_halign (Gtk.Align.END);
            this.unfollow_button.set_tooltip_text (_("Unfollow user"));
            this.buttons_box.pack_start (this.unfollow_button, false, true, 0);

            this.unfollow_button.clicked.connect (() => {
                new Thread<void*> (null, this.unfollow_thread);
            });

            // lists button
            this.lists_button = new Gtk.Button.with_label (_("Add"));
            this.lists_button.set_halign (Gtk.Align.CENTER);
            this.lists_button.set_tooltip_text (_("Add user to list"));
            this.buttons_box.pack_start (this.lists_button, false, true, 0);

            this.lists_button.clicked.connect (() => {
                this.birdie.current_timeline = "own";
                this.birdie.notebook.set_visible_child_name ("own");
                this.birdie.notebook_own.set_visible_child_name("2");
                this.birdie.notebook_own.set_tabs (false);
                this.birdie.adding_to_list = true;
            });

            // block button
            this.block_button = new Gtk.Button.with_label (_("Block"));
            this.block_button.set_halign (Gtk.Align.END);
            this.block_button.set_tooltip_text (_("Block user"));
            this.buttons_box.pack_start (this.block_button, false, true, 0);

            this.block_button.clicked.connect (() => {
                new Thread<void*> (null, this.block_thread);
            });

            // unblock button
            this.unblock_button = new Gtk.Button.with_label (_("Unblock"));
            this.unblock_button.set_halign (Gtk.Align.END);
            this.unblock_button.set_tooltip_text (_("Unblock user"));
            this.buttons_box.pack_start (this.unblock_button, false, true, 0);

            this.unblock_button.clicked.connect (() => {
                new Thread<void*> (null, this.unblock_thread);
            });

            follow_button.get_style_context().add_class ("suggested-action");
            block_button.get_style_context().add_class ("destructive-action");
            unblock_button.get_style_context().add_class ("suggested-action");

            this.unfollow_button.set_no_show_all (true);
            this.unblock_button.set_no_show_all (true);
            this.lists_button.set_no_show_all (true);
            this.follow_button.set_no_show_all (true);
            this.block_button.set_no_show_all (true);

            this.show_all ();
            this.hide_buttons ();

            if (user.verified)
                this.verified_img.show ();
        }

        public void update (User user) {
            this.user = user;
            Array<string> friendship = new Array<string> ();
            this.hide_buttons ();

            this.avatar_box.remove(this.avatar);
            this.avatar = new Granite.Widgets.Avatar.from_file (Environment.get_home_dir () + "/.cache/birdie/" + user.profile_image_file, 50);
            this.avatar.set_halign (Gtk.Align.CENTER);
            this.avatar.set_valign (Gtk.Align.START);
            this.avatar.margin_top = 12;
            this.avatar_box.pack_start (this.avatar, true, true, 0);

            string followed_by = "";

            if (user.screen_name != this.birdie.api.account.screen_name) {
                this.buttons_box.margin_top = 12;

                friendship = this.birdie.api.get_friendship (this.birdie.api.account.screen_name, user.screen_name);
                if (friendship.index (0) == "true") {
                    this.unfollow_button.show ();
                } else {
                    this.follow_button.show ();
                }

                this.lists_button.show ();

                if (friendship.index (1) == "true") {
                    this.unblock_button.show ();
                } else {
                    this.block_button.show ();
                }

                if (friendship.index (2) == "true") {
                    followed_by = _("Following you.");
                } else {
                    followed_by = _("Not following you.");
                }
            }

            string tweets_txt = _("TWEETS");

            description_txt = user.desc + "\n\n<span size='small' color='#444444'>" + followed_by + "</span>" +
                "\n\n<span size='small' color='#444444'>" + tweets_txt +
                " </span><span size='small' font_weight='bold'>" + user.statuses_count.to_string() + "</span>" +
                " | <span size='small' color='#444444'> " + _("FOLLOWING") +
                " </span><span size='small' font_weight='bold'>" + user.friends_count.to_string() + "</span>" +
                " | <span size='small' color='#444444'> " + _("FOLLOWERS") +
                " </span><span size='small' font_weight='bold'>" + user.followers_count.to_string() + "</span>";

            description_txt = description_txt.chomp ();
            description_txt = GLib.Markup.escape_text (description_txt);

            string txt = "<span underline='none' font_weight='bold' size='x-large'>" +
                user.name.chomp () + "</span> <span font_weight='light' color='#444444' size='small'>\n@" + user.screen_name + "</span>";

            if (user.location != "")
                txt = txt +  " | <span size='small'>" + Utils.unescape_html (user.location) + "</span>";

            if (user.website != "")
                txt = txt +  " | <span size='small'><a href='http://" + user.website + "'>" + user.website + "</a></span>";

            if (description_txt != "")
                txt = txt +  "\n\n<span size='small'>" + Utils.unescape_html (description_txt) + "</span>";

            this.username_label.set_markup (txt);

            this.show_all ();
            this.verified_img.hide ();

            if (user.verified)
                this.verified_img.show ();
        }

        public void hide_buttons () {
            this.follow_button.hide ();
            this.unfollow_button.hide ();
            this.block_button.hide ();
            this.unblock_button.hide ();
        }

        private void* follow_thread () {
            Idle.add( () => {
                var reply = this.birdie.api.create_friendship (user.screen_name);

                if (reply == 0) {
                    this.hide_buttons ();
                    this.unfollow_button.show ();
                    this.block_button.show ();
                }
                return false;
            });

            return null;
        }

        private void* unfollow_thread () {
            Idle.add( () => {
                var reply = this.birdie.api.destroy_friendship (user.screen_name);

                if (reply == 0) {
                    this.hide_buttons ();
                    this.follow_button.show ();
                    this.block_button.show ();
                }
                return false;
            });

            return null;
        }

        private void* block_thread () {
            Idle.add( () => {
                var reply = this.birdie.api.create_block (user.screen_name);

                if (reply == 0) {
                    this.hide_buttons ();
                    this.follow_button.show ();
                    this.unblock_button.show ();
                }
                return false;
            });

            return null;
        }

        private void* unblock_thread () {
            Idle.add( () => {
                var reply = this.birdie.api.destroy_block (user.screen_name);

                if (reply == 0) {
                    this.unblock_button.hide ();
                    this.follow_button.show ();
                    this.block_button.show ();
                }
                return false;
            });

            return null;
        }

        public void set_avatar (string avatar_file) {
            Idle.add(() => {
                this.avatar_box.remove(this.avatar);
                this.avatar = new Granite.Widgets.Avatar.from_file (avatar_file, 50);
                this.avatar.set_halign (Gtk.Align.CENTER);
                this.avatar.set_valign (Gtk.Align.START);
                this.avatar.margin_top = 12;
                this.avatar_box.pack_start (this.avatar, true, true, 0);
                this.show_all();
                return false;
            });
        }
    }
}
