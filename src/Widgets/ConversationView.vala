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
    public class ConversationView : Gtk.Box {

    	public signal void return_to_conversations_list();

    	private Gtk.ScrolledWindow conversation_window;
    	private Gtk.Box conversation_box;
    	private Gee.ArrayList<Widgets.TweetBox> tweet_boxes = new Gee.ArrayList<Widgets.TweetBox>();
        private Birdie birdie;
        private string other_party_username = "";

    	public ConversationView(Birdie birdie) {
    	
    		this.orientation = Gtk.Orientation.VERTICAL;
    		this.get_style_context().add_class("white-box");

            this.birdie = birdie;

    		var back_button = new Gtk.Button.with_label(_("Conversations"));
    		back_button.get_style_context().add_class("back-button");
            back_button.margin = 12;
    		back_button.clicked.connect(on_button_click);
    		back_button.expand = false;
    		back_button.halign = Gtk.Align.START;

    		conversation_window = new Gtk.ScrolledWindow(null, null);
    		conversation_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 12);
    		conversation_window.add(conversation_box);
            conversation_window.expand = true;

    		this.add(back_button);
    		this.add(conversation_window);

            var new_message_button = new Gtk.Button.with_label(_("New Message"));
            new_message_button.get_style_context().add_class("suggested-action");
            new_message_button.hexpand = true;
            new_message_button.margin = 12;
            this.add(new_message_button);

            new_message_button.clicked.connect(() => {
                Widgets.TweetDialog dialog = new TweetDialog (this.birdie, "",
                            other_party_username, true);
                dialog.set_relative_to(new_message_button);
                dialog.show_all ();
            });

            this.draw.connect(() => {
                this.scroll_to_bottom();
                return false;
            });
    	}

    	public void set_conversation(string name, Widgets.TweetList received, Widgets.TweetList sent) {

            // Remove all the old messages
            foreach(var child in conversation_box.get_children()) {
                conversation_box.remove(child);
            }

            string screen_name = "";

    		// Go through and find the matching TweetBoxes
            tweet_boxes = new Gee.ArrayList<Widgets.TweetBox>();
            foreach(TweetBox tb in received.boxes) {
                if(tb.tweet.user_name == name) {
                    this.other_party_username = tb.tweet.user_screen_name;
                    tweet_boxes.add(tb);
                    screen_name = tb.tweet.user_screen_name;
                }
            }

            foreach(TweetBox tb in sent.boxes) {
                if(tb.tweet.user_screen_name == screen_name) {
                    tweet_boxes.add(tb);
                }
            }

            // Is this the start of the conversation?
            if(tweet_boxes.size < 1) {
                stdout.puts("Setting OPU to new\n");
                this.other_party_username = "new";
            }

            // Sort by date
            tweet_boxes = sort(tweet_boxes);

            for(int i = tweet_boxes.size - 1; i >= 0; i--) {

                TweetBox tb = tweet_boxes[i];
                TweetBox new_tb = new TweetBox(tb.tweet, tb.birdie);

                try {
                    var pixbuf = new Gdk.Pixbuf.from_file (Environment.get_home_dir () +
                        "/.cache/birdie/" + tb.tweet.profile_image_file);

                    new_tb.avatar.pixbuf = pixbuf.scale_simple(50, 50, Gdk.InterpType.BILINEAR);
                } catch (Error e) {
                    stderr.printf("Error creating avatar: %s\n", e.message);
                }
                conversation_box.add(new_tb);
            }
            
            show_all();
    	}

    	private void on_button_click() {
    		return_to_conversations_list();
    	}

        public void scroll_to_bottom() {
            conversation_window.scroll_child(Gtk.ScrollType.END, false);
        }

        private Gee.ArrayList<TweetBox> sort(Gee.ArrayList<TweetBox> boxes) {

            Gee.HashMap<GLib.DateTime, Widgets.TweetBox> dates_to_boxes = new Gee.HashMap<GLib.DateTime,Widgets.TweetBox>();
            Gee.HashMap<Widgets.TweetBox, GLib.DateTime> boxes_to_dates = new Gee.HashMap<Widgets.TweetBox, GLib.DateTime>();
            Gee.ArrayList<GLib.DateTime> sorted_dates = new Gee.ArrayList<GLib.DateTime> ();
            Gee.ArrayList<TweetBox> sorted_boxes = new Gee.ArrayList<TweetBox>();

            // Go through each of the boxes and get a DateTime object for each time stamped tweet
            foreach(Widgets.TweetBox tb in boxes) {

                GLib.DateTime tb_datetime;

                if(tb.tweet.created_at != null && tb.tweet.created_at.length > 0) {
                    
                    // Split the created_at string into separate fields and parse them accordingly
                    string[] fields = tb.tweet.created_at.split(" ");

                    int year = int.parse(fields[5]);
                    int month = Utils.str_to_month(fields[1]);
                    int day = int.parse(fields[2]);

                    // Split the timestamp into hours, minutes, and seconds
                    string[] time_fields = fields[3].split(":");

                    int hour = int.parse(time_fields[0]);
                    int minute = int.parse(time_fields[1]);
                    int seconds = int.parse(time_fields[2]);

                    // Create a datetime representation
                    tb_datetime = new DateTime.utc(year, month, day, hour, minute, seconds);
                } else {
                    tb_datetime = new DateTime.now_utc();
                }

                // Save both the dates_to_boxes and the boxes_to_dates
                dates_to_boxes.set(tb_datetime, tb);
                boxes_to_dates.set(tb, tb_datetime);

            }

            // Now, repeatedly go through the boxes until we are sorted
            foreach(Widgets.TweetBox tb in boxes) {

                // Get the stored datetime representation
                GLib.DateTime current_box_datetime = boxes_to_dates.get(tb);

                // Find the position to insert by going through the sorted dates and incrementing
                // while the current date is less than or equal to the previously known latest time
                int i = 0;
                while(i < sorted_dates.size && current_box_datetime.compare(sorted_dates[i]) <= 0) { i++; }

                sorted_dates.insert(i, current_box_datetime);
            }

            // At this point, the dates should be in sorted order
            // Just find the corresponding boxes and put them in the arraylist in order
            foreach(GLib.DateTime datetime in sorted_dates) {
                sorted_boxes.add(dates_to_boxes.get(datetime));
            }

            return sorted_boxes;
        }
	}
}
