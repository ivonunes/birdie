namespace Birdie.Widgets {
    public class TweetBox : Gtk.Box {
        public Tweet tweet;
        public Birdie birdie;
        
        private Gtk.Image avatar;
        private Gtk.Box infobox;
        private Gtk.Box userbox;
        private Gtk.Box right;
        private Gtk.Label user_name;
        private Gtk.Label user_screen_name;
        private Gtk.Label text;
        private Gtk.Label created_at;
        private Gtk.Box favoritebox;
        private Gtk.Box retweetbox;
        private Gtk.Box replybox;
        private Gtk.Box delbox;
        private Gtk.Button favorite;
        private Gtk.Button retweet;
        private Gtk.Button reply;
        private Gtk.Button del;
        private Gtk.Label favoritelabel;
        
        private int year;
        private int month;
        private int day;
        private int hour;
        private int minute;
        private int second;
        
        private string date;
    
        public TweetBox (Tweet tweet, Birdie birdie) {
            GLib.Object (orientation: Gtk.Orientation.HORIZONTAL);
            
            this.birdie = birdie;
            this.tweet = tweet;
            
            this.hour = 0;
            this.minute = 0;
            this.second = 0;
            this.day = 0;
            this.month = 0;
            this.year = 0;
            
            this.avatar = new Gtk.Image ();
            this.avatar.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + tweet.profile_image_file);
            this.avatar.set_padding (15, 0);
            
            if ("&" in tweet.user_name)
                tweet.user_name = tweet.user_name.replace ("&", "&amp;");
                
            if ("http://" in tweet.text) {
                
            }
            
            this.user_name = new Gtk.Label (tweet.user_name);
            this.user_name.set_markup ("<span font_weight='bold' size='large'>" + tweet.user_name + "</span>");
            this.user_name.set_alignment (0, 0);
            this.user_screen_name = new Gtk.Label (tweet.user_screen_name);
            this.user_screen_name.set_markup ("<span font_weight='light' color='#aaaaaa'>@" + tweet.user_screen_name + "</span>");
            this.user_screen_name.set_alignment (0, 0.75f);
            this.user_screen_name.set_padding (5, 0);
            this.text = new Gtk.Label (tweet.text);
            this.text.set_markup (tweet.text);
            this.text.set_selectable (true);
            this.text.set_line_wrap (true);
            this.text.set_alignment (0, 0);
            this.created_at = new Gtk.Label ("");
            this.created_at.set_alignment (1, 0);
            
            this.userbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.userbox.pack_start (this.user_name, false, false, 0);
            this.userbox.pack_start (this.user_screen_name, false, false, 0);
            
            this.infobox = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.infobox.pack_start (new Gtk.Label (""), true, true, 0);
            this.infobox.pack_start (this.userbox, false, false, 0);
            this.infobox.pack_start (this.text, false, false, 0);
            this.infobox.pack_start (new Gtk.Label (""), true, true, 0);
            
            this.right = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.right.pack_start (this.created_at, false, false, 0);
            this.right.pack_start (new Gtk.Label (""), true, true, 0);
            
            this.favoritebox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.favorite = new Gtk.Button ();
            this.favoritelabel = new Gtk.Label (" ♥ ");
            this.favorite.child = this.favoritelabel;
            this.favorite.set_tooltip_text (_("Favorite"));
            this.favoritebox.pack_start (new Gtk.Label (""), true, true, 0);
            this.favoritebox.pack_start (favorite, false, false, 0);
            
            this.favorite.clicked.connect (() => {
                this.favorite.set_sensitive (false);
                Thread.create<void*> (this.favorite_thread, true);
		    });
            
            if (this.tweet.favorited) {
                this.favoritelabel.set_markup ("<span color='#D60B0B'> ♥ </span>");
            }
            
            this.right.pack_start (this.favoritebox, false, false, 5);
            
            if (this.tweet.user_screen_name != this.birdie.api.account.screen_name) {
                this.retweetbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                this.retweet = new Gtk.Button.with_label (" ↺ ");
                this.retweet.set_tooltip_text (_("Retweet"));
                this.retweetbox.pack_start (new Gtk.Label (""), true, true, 0);
                this.retweetbox.pack_start (retweet, false, false, 0);
                
                if (this.tweet.retweeted) {
                    this.retweet.set_sensitive (false);
                    this.retweet.set_label (" ✓ ");
                }
                
                this.retweet.clicked.connect (() => {
                    this.retweet.set_sensitive (false);
			        Thread.create<void*> (this.retweet_thread, true);
		        });
                
                this.replybox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                this.reply = new Gtk.Button.with_label (" ↪ ");
                this.reply.set_tooltip_text (_("Reply"));
                this.replybox.pack_start (new Gtk.Label (""), true, true, 0);
                this.replybox.pack_start (reply, false, false, 0);
                            
                this.reply.clicked.connect (() => {
			        Widgets.TweetDialog dialog = new TweetDialog (this.birdie, this.tweet.id, this.tweet.user_screen_name);
			        dialog.show_all ();
		        });
		        
		        this.right.pack_start (this.retweetbox, false, false, 0);
                this.right.pack_start (this.replybox, false, false, 5);
		    } else {
		        this.delbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                this.del = new Gtk.Button.with_label (" ✘ ");
                this.del.set_tooltip_text (_("Delete"));
                this.delbox.pack_start (new Gtk.Label (""), true, true, 0);
                this.delbox.pack_start (del, false, false, 0);
                
                this.del.clicked.connect (() => {
			        this.del.set_sensitive (false);
			        Thread.create<void*> (this.delete_thread, true);
		        });
                
                this.right.pack_start (this.delbox, false, false, 5);
		    }

            this.pack_start (this.avatar, false, false, 0);
            this.pack_start (this.infobox, true, true, 0);
            this.pack_start (this.right, false, false, 5);
            
            this.set_size_request (-1, 100);
            
            this.update_date ();
        }
        
        private void* favorite_thread () {
            int code;
            
			if (this.tweet.favorited) {
			    code = this.birdie.api.favorite_destroy (this.tweet.id);
			    
			    Gdk.threads_enter ();
			    if (code == 0) {
			        this.favoritelabel.set_label (" ♥ ");
			        this.favorite.set_tooltip_text (_("Favorite"));
			        this.tweet.favorited = false;
			    }
			} else {
			    code = this.birdie.api.favorite_create (this.tweet.id);
			    
			    Gdk.threads_enter ();
			    if (code == 0) {
			        this.favoritelabel.set_markup ("<span color='#D60B0B'> ♥ </span>");
			        this.favorite.set_tooltip_text (_("Unfavorite"));
			        this.tweet.favorited = true;
			    }
			}
			this.favorite.set_sensitive (true);
			Gdk.threads_leave ();
			
            return null;
        }
        
        private void* retweet_thread () {
            int code = this.birdie.api.retweet (this.tweet.id);
			
			Gdk.threads_enter ();   
			if (code == 0) {
			    this.retweet.set_label (" ✓ ");
			} else {
			    this.retweet.set_sensitive (true);
			}
			Gdk.threads_leave ();
        
            return null;
        }
        
        private void* delete_thread () {
            int code = this.birdie.api.destroy (this.tweet.id);
			
			Gdk.threads_enter ();
			if (code == 0) {
			    this.birdie.home_list.remove (this.tweet);
			    this.birdie.mentions_list.remove (this.tweet);
			    this.birdie.own_list.remove (this.tweet);
			} else {
			    this.del.set_sensitive (true);
			}
			Gdk.threads_leave ();
        
            return null;
        }
        
        public void update_date () {
            if (this.tweet.created_at == "") {
                this.date = "now";
            } else if (this.day == 0 || this.month == 0 || this.year == 0) {
                string year = this.tweet.created_at.split (" ")[5];
                this.year = int.parse (year);
                
                string month = this.tweet.created_at.split (" ")[1];      
                this.month = Utils.str_to_month (month);
                
                string day = this.tweet.created_at.split (" ")[2];
                this.day = int.parse (day);
            
                string hms = this.tweet.created_at.split (" ")[3];
                
                string hour = hms.split (":")[0];
                this.hour = int.parse (hour);
                
                string minute = hms.split (":")[1];
                this.minute = int.parse (minute);
                
                string second = hms.split (":")[2];
                this.second = int.parse (second);
            }
            
            if (this.tweet.created_at != "") {
                this.date = Utils.pretty_date (this.year, this.month, this.day, this.hour, this.minute, this.second);
            }
            
            this.created_at.set_markup ("<span color='#aaaaaa'>" + this.date + "</span>");
        }
    }
}
