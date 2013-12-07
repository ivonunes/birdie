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
        public GLib.List<Gtk.Separator> separators;

        public MoreButton more_button;

        private bool first;
        public bool load_more;
        private int count;

        public TweetList () {
            GLib.Object (valign: Gtk.Align.START);
            this.first = true;
            this.count = 0;
            this.load_more = false;

            this.set_selection_mode (Gtk.SelectionMode.NONE);

            this.more_button = new MoreButton ();
            this.show_all ();
        }

        public void append (Tweet tweet, Birdie birdie) {
            TweetBox box = new TweetBox(tweet, birdie);
            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            if (this.count > 100) {
                var box_old = this.boxes.nth_data (0);
                var separator_old = this.separators.nth_data (0);
                var row_box_old = this.get_row_for_widget (box_old);
                var row_separator_old = this.get_row_for_widget (separator_old);

                this.separators.remove (separator_old);
                this.boxes.remove (box_old);
                box_old.destroy();
                separator_old.destroy();
                base.remove (row_box_old);
                base.remove (row_separator_old);

                count--;
            }

            boxes.append (box);
            separators.append (separator);

            Idle.add( () => {
                if (!this.first)
                    base.prepend (separator);
                else if (this.load_more)
                    base.prepend (this.more_button.button);

                base.prepend (box);

                if (this.first)
                    this.first = false;

                this.show_all ();

                this.count++;

                return false;
            });
        }

        public new void prepend (Tweet tweet, Birdie birdie) {
            if (this.boxes.nth_data (0).tweet.actual_id != tweet.actual_id) {
                TweetBox box = new TweetBox(tweet, birdie);
                Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

                boxes.prepend (box);
                separators.prepend (separator);

                Idle.add( () => {
                    if (!this.first && this.load_more)
                        base.insert (separator, (int) base.get_children ().length () - 1);
                    else if (!this.first)
                        base.insert (separator, (int) base.get_children ().length ());

                    if (this.load_more)
                        base.insert (box, (int) base.get_children ().length () - 1);
                    else
                        base.insert (box, (int) base.get_children ().length ());

                    if (this.first)
                        this.first = false;

                    this.show_all ();

                    return false;
                });
            }
        }

        public new void remove (Tweet tweet) {
            this.boxes.foreach ((box) => {
                if (box.tweet == tweet) {
                    Idle.add( () => {
                        int separator_index = boxes.index (box);
                        var separator = this.separators.nth_data ((uint) separator_index);
                        var box_row = this.get_row_for_widget (box);
                        var separator_row = this.get_row_for_widget (separator);
                        this.separators.remove (separator);
                        this.boxes.remove (box);
                        box.destroy();
                        separator.destroy();
                        base.remove (box_row);
                        base.remove (separator_row);
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
        }

        public Gtk.ListBoxRow? get_row_for_widget (Gtk.Widget find) {
            foreach (Gtk.Widget w in this.get_children()) {
                if (((Gtk.ListBoxRow) w).get_child () == find) {
                    return (Gtk.ListBoxRow) w;
                }
            }

            return null;
        }

        public string get_oldest () {
            if (this.boxes.nth_data (0).tweet.actual_id != null)
                return this.boxes.nth_data (0).tweet.actual_id;
            else
                return "";
        }
    }
}
