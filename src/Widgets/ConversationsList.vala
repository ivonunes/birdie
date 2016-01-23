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
 
using Gee;

namespace Birdie.Widgets {
    public class ConversationsList : Gtk.Box {

        public signal void conversation_selected(string username);

    	private Widgets.TweetList received;
    	private Widgets.TweetList sent;
        private Gee.ArrayList<string> names;

    	private Gtk.ListBox conversations;

    	public ConversationsList( Widgets.TweetList received, Widgets.TweetList sent) {

    		this.orientation = Gtk.Orientation.VERTICAL;
            this.get_style_context().add_class("white-box");

            // Create a new list box to store conversations
            conversations = new Gtk.ListBox();
            conversations.row_activated.connect(on_row_activated);
            conversations.margin = 12;

            this.add(conversations);

            set_dm_lists(received, sent, true);
    	}

    	public void set_dm_lists(Widgets.TweetList received, Widgets.TweetList sent, bool? init = false) {

            // Remove all the old messages
            foreach(var child in conversations.get_children()) {
                conversations.remove(child);
            }

    		this.received = received;
    		this.sent = sent;

    		// Go through all the tweets and add usernames to the hashset
    		// Using a hash set here will prevent duplicate entries
            var people = new HashMap<string, Granite.Widgets.Avatar>();

    		foreach(TweetBox b in received.boxes) {
                people.set(b.tweet.user_name, b.avatar);
    		}

            /*
    		foreach(TweetBox b in sent.boxes) {
                people.set(b.tweet.user_name, b.avatar);
    		}
            */

            names = new Gee.ArrayList<string>();
    		foreach(string name in people.keys) {
                names.add(name);
            }

            // Sort the names
            CompareDataFunc<string> compare = (a, b) => {
                if(a == b)
                    return 0;
                else if (a > b)
                    return 1;
                else 
                    return -1; 
            };

            names.sort(compare);

            // Set up the new conversation button
            var generic_avatar = new Granite.Widgets.Avatar();

            try {
                var temp_pb = new Gdk.Pixbuf.from_file ("/usr/share/icons/elementary/status/64/avatar-default.svg");
                generic_avatar.pixbuf = temp_pb.scale_simple(50, 50, Gdk.InterpType.BILINEAR);
            } catch (Error e) {
                stderr.printf("Error setting avatar in conversation list: %s\n", e.message);
            }

            string new_conv_name = _("New Conversation…");
            people.set(new_conv_name, generic_avatar);
            names.insert(0, new_conv_name);

            foreach(string name in names) {
    			var name_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
                var name_label = new Gtk.Label(name);
                name_label.get_style_context().add_class("h3");
                Granite.Widgets.Avatar avatar = people.get(name);
                var pixbuf = avatar.pixbuf;
                Granite.Widgets.Avatar new_avatar = new Granite.Widgets.Avatar.from_pixbuf(pixbuf);
                name_box.add(new_avatar);
    			name_box.add(name_label);
                new_avatar.margin_left = 0;
                name_box.margin_left = 0;
    			conversations.add(name_box);
    		}

    		show_all();
    	}

        private void on_row_activated(Gtk.ListBoxRow row) {
            int index = row.get_index();
            conversation_selected(names[index]);
        }  
	}
}