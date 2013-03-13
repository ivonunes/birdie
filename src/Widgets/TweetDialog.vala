namespace Birdie.Widgets {
    public class TweetDialog : LightDialog {
        Gtk.Image avatar;
        Gtk.TextView view;
        Gtk.Label count_label;
        int count;
        Gtk.Button tweet;
        
        bool tweet_disabled;
        
        string id;
    
        Birdie birdie;
    
        public TweetDialog (Birdie birdie, string id = "", string user_screen_name = "") {
            this.birdie = birdie;
            this.id = id;
            
            this.avatar = new Gtk.Image ();
            this.avatar.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + this.birdie.api.account.profile_image_file);
        
            this.view = new Gtk.TextView ();
            this.view.set_wrap_mode (Gtk.WrapMode.WORD_CHAR);
            this.view.set_size_request(300, 80);
            
            if (id != "" && user_screen_name != "")
                this.view.buffer.insert_at_cursor ("@" + user_screen_name + " ", -1);

            var top = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            var avatarbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            avatarbox.pack_start (this.avatar, false, false, 0);
            avatarbox.pack_start (new Gtk.Label (""), true, true, 0);
            avatarbox.margin_right = 12;
            top.add (avatarbox);
            top.add (this.view);
            top.margin = 12;
            
            this.view.buffer.changed.connect (() => {
			    this.count = 140 - this.view.buffer.get_char_count ();
			    this.count_label.set_markup ("<span color='#777777'>" + this.count.to_string () + "</span>");
			    
			    if (this.count < 0 || this.count == 140) {
			        this.tweet.set_sensitive (false);
			        this.tweet_disabled = true;
			    } else if (this.tweet_disabled) {
			        this.tweet.set_sensitive (true);
			        this.tweet_disabled = false;
			    }
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
            
			this.tweet = new Gtk.Button.with_label (_("Tweet"));
			this.tweet.set_size_request (100, -1);
			this.tweet.set_sensitive (false);
			this.tweet.margin_left = 6;
			
			this.tweet.clicked.connect (() => {
			    new Thread<void*> (null, this.tweet_thread);
            });
			
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

            this.hide ();
			birdie.tweet_callback (this.view.buffer.get_text (start, end, false), this.id);
			this.destroy ();
			
            return null;
        }
    }
}
