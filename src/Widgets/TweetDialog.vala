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
    public class TweetDialog : LightDialog {
        Gtk.Image avatar;
        Gtk.TextView view;
        Gtk.Entry entry;
        Gtk.Label count_label;
        int count;
        Gtk.Button tweet;
        
        bool tweet_disabled;
        
        string id;
        string user_screen_name;
        bool dm;
        
        private string filler;
        private int count_remaining;
        private string virtual_text;
        
        private Regex urls;
    
        Birdie birdie;
    
        public TweetDialog (Birdie birdie, string id = "", string user_screen_name = "", bool dm = false) {
            this.birdie = birdie;
            this.id = id;
            this.user_screen_name = user_screen_name;
            this.dm = dm;
            
            this.avatar = new Gtk.Image ();
            this.avatar.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + this.birdie.api.account.profile_image_file);
        
            this.view = new Gtk.TextView ();
            this.view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            this.view.set_size_request(300, 80);
            
            var dm_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
            this.entry = new Gtk.Entry ();
            if (dm && user_screen_name == "") {
                this.entry.set_text ("@");

                this.entry.get_buffer ().inserted_text.connect (() => {
                    buffer_changed ();
                });

                this.entry.get_buffer ().deleted_text.connect (() => {
                    buffer_changed ();
                });
                
                dm_box.add (this.entry);
                dm_box.add (this.view);
            }
            
            if (!dm) {
                if (id != "" && user_screen_name != "")
                    this.view.buffer.insert_at_cursor ("@" + user_screen_name + " ", -1);
            }

            var top = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var avatarbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            avatarbox.pack_start (this.avatar, false, false, 0);
            avatarbox.pack_start (new Gtk.Label (""), true, true, 0);
            avatarbox.margin_right = 12;
            top.add (avatarbox);
            if (dm && user_screen_name == "")
                top.add (dm_box);
            else
                top.add (this.view);
            top.margin = 12;
            
            this.view.buffer.changed.connect (() => {
                buffer_changed ();
            });

            this.tweet_disabled = true;
            this.count = 140;
            this.count_label = new Gtk.Label (this.count.to_string ());
            this.count_label.set_markup ("<span color='#777777'>" + this.count.to_string () + "</span>");
        
            Gtk.Button cancel = new Gtk.Button.with_label (_("Cancel"));
            cancel.set_size_request (100, -1);
            cancel.clicked.connect (() => {
			    this.destroy ();
            });
            
            if (dm)
                this.tweet = new Gtk.Button.with_label (_("Send"));
            else
                if (birdie.service == 0)
                    this.tweet = new Gtk.Button.with_label (_("Tweet"));
                else
                    this.tweet = new Gtk.Button.with_label (_("New status"));
			this.tweet.set_size_request (100, -1);
			this.tweet.margin_left = 6;
			this.tweet.set_sensitive (false);
			
			this.tweet.clicked.connect (() => {
			    new Thread<void*> (null, this.tweet_thread);
            });
			
			var d_provider = new Gtk.CssProvider ();
            string css_dir = "/usr/share/themes/elementary/gtk-3.0";
		    File file = File.new_for_path (css_dir);
		    File child = file.get_child ("button.css");	    

		    try
		    {
			    d_provider.load_from_file (child);
		    }
		    catch (GLib.Error error)
		    {
			    stderr.printf("Could not load css for button: %s", error.message);
		    }
			
			this.tweet.get_style_context ().add_provider (d_provider, Gtk.STYLE_PROVIDER_PRIORITY_THEME);
			this.tweet.get_style_context().add_class ("affirmative");
			
			Gtk.Box bottom = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			bottom.pack_start (this.count_label, false, false, 0);
			bottom.pack_start (new Gtk.Label (""), true, true, 0);
			bottom.pack_start (cancel, false, false, 0);
			bottom.pack_start (this.tweet, false, false, 0);
			bottom.margin = 12;
			
			this.add (top);
			this.add (bottom);
			
			this.show_all ();
        }
        
        private void* tweet_thread () {
            Gtk.TextIter start;
			Gtk.TextIter end;
			    
			this.view.buffer.get_start_iter (out start);
			this.view.buffer.get_end_iter (out end);

            if (dm && this.user_screen_name == "")
                this.user_screen_name = this.entry.get_text ();

            this.hide ();
            birdie.tweet_callback (this.view.buffer.get_text (start, end, false), this.id, this.user_screen_name, this.dm);
			this.destroy ();
			
            return null;
        }

        private void buffer_changed () {
            Gtk.TextIter start;
            Gtk.TextIter end;

            var tmp_entry = this.entry.get_text ();
            
            this.count_remaining = 140;
            
            // a filler to fake virtual string controller with shortened urls
            this.filler = "0123456789012345678901";
            
            this.view.buffer.get_start_iter (out start);
            this.view.buffer.get_end_iter (out end);
            
            virtual_text = this.view.buffer.get_text (start, end, false);
            
            try {
                urls = new Regex("((http|https|ftp)://([\\S]+))");
            } catch (RegexError e) {
                warning ("regex error: %s", e.message);
            }
        
            // replace urls with filler to fill them with 20 chars each
            try {
                virtual_text = urls.replace (virtual_text, -1, 0, filler);
            }
            catch (Error e) {
                warning ("url replacing error: %s", e.message);
            }
            
            this.count = 140 - virtual_text.char_count ();
            this.count_label.set_markup ("<span color='#777777'>" + this.count.to_string () + "</span>");
            
            if ((this.count < 0 || this.count >= 140) || (" " in tmp_entry && dm) || (this.entry.get_buffer ().length < 3 && dm)) {
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
