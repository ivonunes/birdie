// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2013-2014 Birdie Developers (http://birdieapp.github.io)
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

        private bool first;
        public bool load_more;
        private int count;
        public string list_id;
        public string list_owner;

        public TweetList () {
            GLib.Object (valign: Gtk.Align.START);
            this.first = true;
            this.count = 0;
            this.load_more = false;

            this.list_id = "";
            this.list_owner = "";

            this.set_selection_mode (Gtk.SelectionMode.NONE);

            this.more_button = new MoreButton ();
            this.show_all ();
        }

        public void append (Tweet tweet, Birdie birdie) {
            TweetBox box;
            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            if (this.list_id != "") {
                box = new TweetBox(tweet, birdie, false, this.list_id, this.list_owner);
            } else {
                box = new TweetBox(tweet, birdie);
            }

            if (this.count > 100) {
                this.boxes.remove ((TweetBox) this.get_row_at_index ((int) this.get_children ().length () - 1).get_child ());
                base.remove (this.get_row_at_index ((int) this.get_children ().length () - 1));
                base.remove (this.get_row_at_index ((int) this.get_children ().length () - 1));
                count--;
            }

            boxes.append (box);

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
            bool separator_next = false;

            this.get_children ().foreach ((row) => {
                if (row is Gtk.ListBoxRow) {
                    var box = ((Gtk.ListBoxRow) row).get_child ();

                    if ((box is TweetBox)) {
                        if (((TweetBox) box).tweet == tweet) {
                            separator_next = true;

                            Idle.add( () => {
                                base.remove (row);
                                this.count--;
                                return false;
                            });
                        }
                    } else if (separator_next) {
                        base.remove (row);
                        separator_next = false;
                    }
                }
            });
        }

        public void remove_by_user (string screen_name) {
            bool separator_next = false;

            this.get_children ().foreach ((row) => {
                if (row is Gtk.ListBoxRow) {
                    var box = ((Gtk.ListBoxRow) row).get_child ();

                    if ((box is TweetBox)) {
                        if (((TweetBox) box).tweet.user_screen_name == screen_name) {
                            separator_next = true;

                            Idle.add( () => {
                                base.remove (row);
                                this.count--;
                                return false;
                            });
                        }
                    } else if (separator_next) {
                        base.remove (row);
                        separator_next = false;
                    }
                }
            });
        }

        public void update_date () {
            this.get_children ().foreach ((row) => {
                if (row is Gtk.ListBoxRow) {
                    var box = ((Gtk.ListBoxRow) row).get_child ();

                    if ((box is TweetBox)) {
                        ((TweetBox) box).update_date ();
                    }
                }
            });
        }

        public void update_display (Tweet tweet, bool? favorite = false) {
            Idle.add( () => {
                this.get_children ().foreach ((row) => {

                    if (row is Gtk.ListBoxRow) {
                        var box = ((Gtk.ListBoxRow) row).get_child ();

                        if ((box is TweetBox)) {

                            if (((TweetBox) box).tweet.actual_id == tweet.actual_id) {
                                ((TweetBox) box).tweet = tweet;
                                if (favorite)
                                    ((TweetBox) box).update_favorites ();
                                else
                                    ((TweetBox) box).update_media ();
                            }
                        }
                    }
                });
                return false;
            });
        }

        public void clear () {
            foreach (Gtk.Widget w in this.get_children()) {
                if (((Gtk.ListBoxRow) w).get_child () != this.more_button.button && (w is Gtk.ListBoxRow)) {
                    Idle.add (() => {
                        base.remove (w);
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
