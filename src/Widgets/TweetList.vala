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
    public class TweetList : Gtk.Box {
        public GLib.List<TweetBox> boxes;
        public GLib.List<Gtk.Separator> separators;

        bool first;
        int count;

        public TweetList () {
            GLib.Object (orientation: Gtk.Orientation.VERTICAL, valign: Gtk.Align.START);
            this.first = true;
            this.count = 0;
        }

        public void append (Tweet tweet, Birdie birdie) {
            TweetBox box = new TweetBox(tweet, birdie);
            Gtk.Separator separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

            if (this.count > 100) {
                var box_old = this.boxes.nth_data (0);
                var separator_old = this.separators.nth_data (0);

                this.separators.remove (separator_old);
                this.boxes.remove (box_old);
                box_old.destroy();
                separator_old.destroy();
            }

            boxes.append (box);
            separators.append (separator);

            Idle.add( () => {
                if (!this.first)
                    this.pack_end (separator, false, false, 0);
                this.pack_end (box, false, false, 0);

                if (this.first)
                    this.first = false;

                this.show_all ();

                this.count++;

                return false;
            });
        }

        public new void remove (Tweet tweet) {
            this.boxes.foreach ((box) => {
                if (box.tweet == tweet) {
                    Idle.add( () => {
                        int separator_index = boxes.index (box);
                        var separator = this.separators.nth_data ((uint) separator_index);
                        this.separators.remove (separator);
                        this.boxes.remove (box);
                        box.destroy();
                        separator.destroy();
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
            this.boxes.foreach ((box) => {
                Idle.add (() => {
                    base.remove (box);
                    this.boxes.remove (box);
                    box.destroy ();
                    return false;
                });
            });

            this.separators.foreach ((sep) => {
                Idle.add (() => {
                    base.remove (sep);
                    this.separators.remove (sep);
                    sep.destroy ();
                    return false;
                });
            });
        }
    }
}
