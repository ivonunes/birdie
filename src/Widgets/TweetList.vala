namespace Birdie.Widgets {
    public class TweetList : Gtk.Box {
        public GLib.List<TweetBox> boxes;
        public GLib.List<Gtk.Separator> separators;
        
        bool first;
    
        public TweetList () {
            GLib.Object (orientation: Gtk.Orientation.VERTICAL);
            this.first = true;
        }
        
        public void append (Tweet tweet, Birdie birdie) {
            Idle.add( () => {
                TweetBox box = new TweetBox(tweet, birdie);
                Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
            
                boxes.append (box);
                separators.append (separator);
            
            
                if (!this.first)
                    this.pack_end (separator, false, false, 0);
                this.pack_end (box, false, false, 0);
            
                if (this.first)
                    this.first = false;
            
                this.show_all ();
                
                return false;
            });
        }
        
        public new void remove (Tweet tweet) {
            this.boxes.foreach ((box) => {
                if (box.tweet == tweet) {
                    Idle.add( () => {
                        int separator_index = boxes.index (box);
                        var separator = this.separators.nth_data ((uint) separator_index);
                        base.remove (box);
                        base.remove (separator);
                        this.separators.remove (separator);
                        this.boxes.remove (box);
                        return false;
                    });
                }
	        });
        }
        
        public void update_date () {
            this.boxes.foreach ((box) => {
                box.update_date ();
	        });
        }
        
        public void set_selectable (bool select) {
            if (this.boxes.length () > 0) {
                Idle.add( () => {
                    var box = this.boxes.nth_data (this.boxes.length () - 1);
                    
                    box.set_selectable (select);
                    
                    return false;
                });
            }
        }
    }
}
