// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2018 Amuza Limited
 *
 * This software is licensed under the GNU General Public License
 * (version 3 or later). See the COPYING file in this distribution.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this software; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Ivo Nunes <ivo@amuza.uk>
 *              Vasco Nunes <vasco@amuza.uk>
 *              Nathan Dyer <mail@nathandyer.me>
 */

namespace Birdie.Widgets {

    public class TweetDialog : Gtk.Popover {

        Granite.Widgets.Avatar avatar;
        Gtk.SourceView view;
        Gtk.Entry entry;
        Gtk.EntryCompletion entry_completion;
        Gtk.Label count_label;
        int count;
        Gtk.Button tweet;
        Gtk.Image file_chooser_btn_image;
        Gtk.FileChooserDialog file_chooser;
        Gtk.Button file_chooser_btn;
        bool tweet_disabled;
        Gtk.Button cancel;
        Gtk.TreeIter iter;
        Gtk.ListStore list_store;
        string id;
        string user_screen_name;
        bool dm;
        bool has_media;
        private string filler;
        private int count_remaining;
        private string virtual_text;
        private int opening_x;
        private int opening_y;
        private Regex urls;
        private string media_uri;

        Birdie birdie;

        private Gtk.Box container;

        public TweetDialog (Birdie birdie, string id = "",
            string user_screen_name = "", bool dm = false) {

            this.birdie = birdie;
            this.id = id;
            this.user_screen_name = user_screen_name;
            this.dm = dm;
            this.count_remaining = 280;
            this.has_media = false;

            this.container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

            this.media_uri = "";

            this.set_modal (true);

            this.avatar = new Granite.Widgets.Avatar();

            avatar = new Granite.Widgets.Avatar();
            try {
                var pixbuf = new Gdk.Pixbuf.from_file (Environment.get_home_dir () +
                "/.cache/birdie/" + this.birdie.api.account.profile_image_file);
                avatar.pixbuf = pixbuf.scale_simple(64, 64, Gdk.InterpType.BILINEAR);
            } catch (Error e) {
                stderr.printf("Error setting avatar in dialog: %s\n", e.message);
            }

            this.view = new Gtk.SourceView ();
            this.view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            this.view.set_size_request(300, 80);
            this.view.set_accepts_tab (false);
            this.view.left_margin = 5;
            this.view.right_margin = 5;
            this.view.cursor_visible = true;

            var dm_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            this.entry = new Gtk.Entry ();
            this.entry_completion = new Gtk.EntryCompletion ();

            // usernames completion
            this.entry.set_completion (entry_completion);

            // Create and register a ListStore for completion
            this.list_store = new Gtk.ListStore (1, typeof (string), typeof (string));
            entry_completion.set_model (list_store);
            entry_completion.set_text_column (0);
            entry_completion.set_inline_completion (true);
            entry_completion.set_inline_selection (true);

            // fill ListStore from db
            foreach (string user in this.birdie.db.get_users (this.birdie.default_account_id)) {
                list_store.append (out iter);
                list_store.set (iter, 0, user);
            }

            view.completion.get_providers ().foreach ((p) => {
                try {
                    view.completion.remove_provider (p);
                } catch (Error e) {
                    warning (e.message);
                }
            });

            view.completion.accelerators = 0;

            var comp_provider = new CompletionProvider (this.view, this.birdie.default_account_id);
            comp_provider.priority = 1;
            comp_provider.name = _("Suggestions");

            try {
                this.view.completion.add_provider (comp_provider);
            } catch (Error e) {
                warning (e.message);
            }

            if (id != "" && user_screen_name != "") {
                if ("@" in user_screen_name) {
                    this.view.buffer.insert_at_cursor (" " + user_screen_name, -1);

                    Gtk.TextIter start;
                    this.view.buffer.get_start_iter (out start);

                    this.view.buffer.place_cursor (start);
                } else {
                    this.view.buffer.insert_at_cursor ("@" + user_screen_name + " ", -1);
                }
            }
        

            var top = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var avatarbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            avatarbox.pack_start (this.avatar, false, false, 0);
            avatarbox.pack_start (new Gtk.Label (""), true, true, 0);
            avatarbox.margin_right = 12;
            top.add (avatarbox);

            Gtk.Box dm_and_view_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);

            if(this.dm) {
                if(user_screen_name == "new") {
                    this.entry.set_text ("@");
                    this.entry.hexpand = true;
                    var label = new Gtk.Label(_("Send a DM to "));
                    var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
                    hbox.add(label);
                    hbox.add(this.entry);
                    dm_and_view_box.add (hbox);
                } else {
                    var label = new Gtk.Label(_("Send a DM to @" + user_screen_name));
                    dm_and_view_box.add(label);
                }
            }

            Gtk.Box view_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
            view_box.get_style_context().add_class("tweet-entry");

            view_box.add(this.view);
            dm_and_view_box.add(view_box);
            top.add (dm_and_view_box);
            
            top.margin = 12;

            this.view.buffer.changed.connect (() => {
                buffer_changed ();
            });

            this.tweet_disabled = true;
            this.count = this.count_remaining;
            this.count_label = new Gtk.Label (this.count.to_string ());
            this.count_label.set_markup ("<span color='#777777'>" + this.count.to_string () + "</span>");

            this.cancel = new Gtk.Button.with_label (_("Cancel"));
            this.cancel.set_size_request (100, -1);
            this.cancel.clicked.connect (() => {
                this.view.get_buffer ().set_text("");
                this.destroy ();
            });

            if (this.dm)
                this.tweet = new Gtk.Button.with_label (_("Send"));
            else
                this.tweet = new Gtk.Button.with_label (_("Tweet"));
            this.tweet.set_size_request (100, -1);
            this.tweet.margin_left = 6;
            this.tweet.set_sensitive (false);

            this.tweet.clicked.connect (() => {
                new Thread<void*> (null, this.tweet_thread);
            });

            this.tweet.get_style_context().add_class ("suggested-action");

            this.file_chooser_btn = new Gtk.Button();
            this.file_chooser_btn.set_tooltip_text (_("Add a picture"));
            this.file_chooser_btn_image = new Gtk.Image.from_icon_name ("insert-image-symbolic", Gtk.IconSize.MENU);
            this.file_chooser_btn.set_image (this.file_chooser_btn_image);
            this.file_chooser_btn.set_relief (Gtk.ReliefStyle.NONE);
            this.file_chooser_btn.margin_right = 6;

            // Emitted when media icon is clicked
            file_chooser_btn.clicked.connect (() => {
                on_add_photo_clicked ();
            });

            Gtk.Box bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            bottom.pack_start (this.count_label, false, false, 0);
            bottom.pack_start (new Gtk.Label (""), true, true, 0);
            bottom.pack_start (this.file_chooser_btn, false, false, 0);
            bottom.pack_start (this.cancel, false, false, 0);
            bottom.pack_start (this.tweet, false, false, 0);
            bottom.margin = 12;

            Gtk.Box content_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
            content_box.add(top);
            content_box.add(bottom);
            this.add(content_box);
            this.show_all ();
            this.buffer_changed ();
        }

        private void on_add_photo_clicked () {
            this.file_chooser = new Gtk.FileChooserDialog (_("Select a Picture"), this.birdie.m_window,
            Gtk.FileChooserAction.OPEN,
            _("Cancel"), Gtk.ResponseType.CANCEL,
            _("Open"), Gtk.ResponseType.OK);

            // filter to jpg, png and gif:
            Gtk.FileFilter filter = new Gtk.FileFilter ();
            this.file_chooser.set_filter (filter);
            filter.add_mime_type ("image/jpeg");
            filter.add_mime_type ("image/png");
            filter.add_mime_type ("image/gif");
            //

            // Add a preview widget:
            Gtk.Image preview_area = new Gtk.Image ();

            file_chooser.set_preview_widget (preview_area);
            file_chooser.update_preview.connect (() => {
                string uri = file_chooser.get_preview_uri ();
                // We only display local files:
                if (uri.has_prefix ("file://") == true) {
                    try {
                        Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file (uri.substring (7));
                        Gdk.Pixbuf scaled = pixbuf.scale_simple (150, 150, Gdk.InterpType.BILINEAR);
                        preview_area.set_from_pixbuf (scaled);
                        preview_area.show ();
                    } catch (Error e) {
                        preview_area.hide ();
                    }
                } else {
                    preview_area.hide ();
                }
            });

            if (this.file_chooser.run () == Gtk.ResponseType.OK) {
                SList<string> uris = file_chooser.get_uris ();
                foreach (unowned string uri in uris) {
                    this.media_uri = uri;
                }
                try {
                    Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file (this.file_chooser.get_filename ());
                    Gdk.Pixbuf scaled = pixbuf.scale_simple (16, 16, Gdk.InterpType.BILINEAR);
                    this.file_chooser_btn_image = new Gtk.Image.from_pixbuf (scaled);
                    this.file_chooser_btn.set_image (this.file_chooser_btn_image);
                    this.has_media = true;
                    buffer_changed ();
                } catch (Error e) {
                    preview_area.hide ();
                }
            }
            this.file_chooser.destroy ();
        }

        private void* tweet_thread () {
            Gtk.TextIter start;
            Gtk.TextIter end;

            if(dm && this.user_screen_name == "new") {
                this.user_screen_name = this.entry.get_text();
            }

            this.view.buffer.get_start_iter (out start);
            this.view.buffer.get_end_iter (out end);

            this.hide ();
            birdie.tweet_callback (this.view.buffer.get_text (start, end, false),
                this.id, this.user_screen_name, this.dm, this.media_uri);

            Idle.add (() => {
                // Clear the buffer once the Tweet has been sent
                this.view.buffer.delete(ref start, ref end);
                return false;
            });

            return null;
        }

        private void buffer_changed () {
            Gtk.TextIter start;
            Gtk.TextIter end;

            if (this.has_media)
                this.count_remaining = 260;
            else
                this.count_remaining = 280;

            var tmp_entry = this.entry.get_text ();

            // a filler to fake virtual string controller with shortened urls
            this.filler = "0123456789012345678901";

            this.view.buffer.get_start_iter (out start);
            this.view.buffer.get_end_iter (out end);

            virtual_text = this.view.buffer.get_text (start, end, false);

            try {
                urls = new Regex("((https?://|ftp://|www.)([\\S]+))");
            } catch (RegexError e) {
                warning ("regex error: %s", e.message);
            }

            // replace urls with filler to fill them with 22 chars each
            try {
                virtual_text = urls.replace (virtual_text, -1, 0, filler);
            }
            catch (Error e) {
                warning ("url replacing error: %s", e.message);
            }

            this.count = this.count_remaining - virtual_text.char_count ();
            this.count_label.set_markup ("<span color='#777777'>" + this.count.to_string () + "</span>");

            if ((this.count < 0 || this.count >= 280) || (" " in tmp_entry && dm && this.entry.get_visible ()) || (this.entry.get_buffer ().length < 3 && dm && this.entry.get_visible ())) {
                // make remaining chars indicator red to warn user
                if (this.count < 0) {
                    this.count_label.set_markup ("<span color='#FF0000'>" + this.count.to_string () + "</span>");
                }
                this.tweet.set_sensitive (false);
                this.tweet_disabled = true;
            } else if (this.tweet_disabled) {
                this.tweet.set_sensitive (true);
                this.tweet_disabled = false;
            }
        }
    }
}
