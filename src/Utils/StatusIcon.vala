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

namespace Birdie.Utils {
	public class StatusIcon : Gtk.StatusIcon {
	    private Gtk.Menu traymenu;
	    private Settings settings;
	    private Gtk.Window m_window;
		private Birdie birdie;

	    public StatusIcon (Birdie birdie) {
	    	this.birdie = birdie;
	    	this.settings = birdie.settings;
	    	this.m_window = birdie.m_window;
	        this.visible = true;
	        this.icon_name = "birdie";
	        this.has_tooltip = true;
	        this.set_tooltip_text (_("Birdie"));
	        construct_traymenu ();
	        activate.connect (this.toggle_window_visibility);
	        this.popup_menu.connect ((button, time) => {traymenu.popup (null, null, null, button, time); });
	    }

	    private void construct_traymenu() {
	        traymenu = new Gtk.Menu();

	        /* New Tweet */
			var menu_tweet = new Gtk.MenuItem.with_label (_("New Tweet"));
			menu_tweet.activate.connect (new_tweet);
			traymenu.append (menu_tweet);

	        /* New dm */
			var menu_dm = new Gtk.MenuItem.with_label (_("New Direct Message"));
			menu_dm.activate.connect (new_dm);
			traymenu.append (menu_dm);

	        /* Separator */
			var menu_sep1 = new Gtk.SeparatorMenuItem ();
			traymenu.append (menu_sep1);

			/* Quit */
			var menu_quit = new Gtk.MenuItem.with_label (_("Quit"));
			menu_quit.activate.connect (exit);
			traymenu.append (menu_quit);

			traymenu.show_all ();
	    }

	    private void new_tweet () {
	    	Widgets.TweetDialog dialog = new Widgets.TweetDialog (birdie);
            dialog.show_all ();
	    }

	    private void new_dm () {
	    	Widgets.TweetDialog dialog = new Widgets.TweetDialog (birdie, "", "", true);
            dialog.show_all ();
	    }

	    private void exit () {
	    	// save window size and position
            int x, y, w, h;
            this.m_window.get_position (out x, out y);
            this.m_window.get_size (out w, out h);
            this.settings.set_int ("opening-x", x);
            this.settings.set_int ("opening-y", y);
            this.settings.set_int ("window-width", w);
            this.settings.set_int ("window-height", h);
            this.m_window.destroy ();
	    }

	    private void toggle_window_visibility () {

	        if (this.m_window.visible) {
	            this.m_window.hide ();
	        }
	        else {
	        	this.m_window.show_all ();
	        	this.m_window.present ();
	        }
	    }
	}
}
