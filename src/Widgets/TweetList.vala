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
 * Authored by: Ivo Nunes <ivoavnunes@gmail.com>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie.Widgets {
    public class TweetList : Gtk.ListBox {
        public GLib.List<TweetBox> boxes;

        public MoreButton more_button;

        bool first;
        int count;

        public TweetList () {
            GLib.Object (valign: Gtk.Align.START);
            this.first = true;
            this.count = 0;

            this.set_selection_mode (Gtk.SelectionMode.NONE);

            this.more_button = new MoreButton ();
            this.more_button.set_no_show_all (true);
            base.prepend (this.more_button);
        }

        public void append (Tweet tweet, Birdie birdie) {
            TweetBox box = new TweetBox(tweet, birdie);

            if (this.count > 100) {
                var box_old = this.boxes.nth_data (0);

                this.boxes.remove (box_old);
                box_old.destroy();
            }

            boxes.append (box);

            Idle.add( () => {
                base.prepend (box);

                if (this.first)
                    this.first = false;

                this.more_button.set_no_show_all (false);
                this.show_all ();
                this.more_button.set_no_show_all (true);

                this.count++;

                return false;
            });
        }

        public new void prepend (Tweet tweet, Birdie birdie) {
            if (this.boxes.nth_data (0).tweet.actual_id != tweet.actual_id) {
                TweetBox box = new TweetBox(tweet, birdie);

                boxes.prepend (box);

                Idle.add( () => {
                    base.prepend (box);

                    //this.reorder_child (box, 1);

                    if (this.first)
                        this.first = false;

                    this.more_button.set_no_show_all (false);
                    this.show_all ();
                    this.more_button.set_no_show_all (true);

                    return false;
                });
            }
        }

        public new void remove (Tweet tweet) {
            this.boxes.foreach ((box) => {
                if (box.tweet == tweet) {
                    Idle.add( () => {
                        this.boxes.remove (box);
                        box.destroy();
                        this.count--;
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

        public void update_display (Tweet tweet) {
            this.boxes.foreach ((box) => {
                if (box.tweet == tweet) {
                    Idle.add( () => {
                        box.update_display ();
                        return false;
                    });
                }
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

        public void clear () {
            foreach (Gtk.Widget w in this.get_children()) {
                if (w != this.more_button) {
                    Idle.add (() => {
                        w.destroy ();
                        return false;
                    });
                }
            }

            Idle.add (() => {
                this.more_button.hide ();
                return false;
            });
        }

        public string get_oldest () {
            if (this.boxes.nth_data (0).tweet.actual_id != null)
                return this.boxes.nth_data (0).tweet.actual_id;
            else
                return "";
        }
    }
}
