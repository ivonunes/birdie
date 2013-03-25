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
 * Authored by: Ivo Nunes <ivo@elementaryos.org>
 *              Vasco Nunes <vascomfnunes@gmail.com>
 */

namespace Birdie.Widgets {
    public class TweetBox : Gtk.Box {
        public Tweet tweet;
        public Birdie birdie;

        private Gtk.Box tweet_box;
        private Gtk.Alignment avatar_alignment;
        private Gtk.Image avatar_img;
        private Gtk.Alignment content_alignment;
        private Gtk.Box content_box;
        private Gtk.Label username_label;
        private Gtk.Label tweet_label;
        private Gtk.Label info_label;
        private Gtk.Alignment buttons_alignment;
        private Gtk.Box buttons_box;
        private Gtk.Label time_label;
        private Gtk.Button favorite_button;
        private Gtk.Button retweet_button;
        private Gtk.Button reply_button;
        private Gtk.Button delete_button;
        private Gtk.Image favorite_icon;
        private Gtk.Image retweet_icon;
        private Gtk.Image reply_icon;
        private Gtk.Image delete_icon;

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

            // tweet box
            this.tweet_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.pack_start (this.tweet_box, true, true, 0);

            // avatar alignment
            this.avatar_alignment = new Gtk.Alignment (0,0,0,1);
            this.avatar_alignment.top_padding = 0;
            this.avatar_alignment.right_padding = 6;
            this.avatar_alignment.bottom_padding = 0;
            this.avatar_alignment.left_padding = 12;
            this.tweet_box.pack_start (this.avatar_alignment, false, true, 0);

            // avatar image
            this.avatar_img = new Gtk.Image ();
            this.avatar_img.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + tweet.profile_image_file);
            this.avatar_img.set_halign (Gtk.Align.START);
            this.avatar_img.set_valign (Gtk.Align.CENTER);
            this.avatar_alignment.add (this.avatar_img);

            // content alignment
            this.content_alignment = new Gtk.Alignment (0,0,0,1);
            this.content_alignment.top_padding = 0;
            this.content_alignment.right_padding = 6;
            this.content_alignment.bottom_padding = 0;
            this.content_alignment.left_padding = 6;
            this.content_alignment.set_valign (Gtk.Align.CENTER);
            this.tweet_box.pack_start (this.content_alignment, false, false, 0);

            // content box
            this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.content_box.set_valign (Gtk.Align.CENTER);
            this.content_alignment.add (this.content_box);

            if ("&" in tweet.user_name)
                tweet.user_name = tweet.user_name.replace ("&", "&amp;");

            if ("< " in tweet.text)
                tweet.text = tweet.text.replace ("< ", "&lt;");

            if (" >" in tweet.text)
                tweet.text = tweet.text.replace (" >", "&gt;");

            // user label
            this.username_label = new Gtk.Label (tweet.user_name);
            this.username_label.set_halign (Gtk.Align.START);
            this.username_label.margin_bottom = 6;

            this.username_label.set_markup ("<span underline='none' color='#000000' font_weight='bold' size='large'><a href='birdie://user/" + tweet.user_screen_name + "'>" + tweet.user_name + "</a></span> <span font_weight='light' color='#aaaaaa'>@" + tweet.user_screen_name + "</span>");
            this.content_box.pack_start (this.username_label, false, true, 0);

            // tweet
            this.tweet_label = new Gtk.Label (tweet.text);
            this.tweet_label.set_markup (tweet.text);
            this.tweet_label.set_selectable (true);
            this.tweet_label.set_line_wrap (true);
            this.tweet_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            this.tweet_label.set_halign (Gtk.Align.START);
            this.tweet_label.xalign = 0;
            this.content_box.pack_start (this.tweet_label, false, true, 0);

            // css
			Gtk.StyleContext ctx = this.tweet_label.get_style_context();
			ctx.add_class("tweet");
			//

            // info footer
            this.set_footer ();

            // buttons alignment
            this.buttons_alignment = new Gtk.Alignment (0,0,1,1);
            this.buttons_alignment.top_padding = 6;
            this.buttons_alignment.right_padding = 12;
            this.buttons_alignment.bottom_padding = 6;
            this.buttons_alignment.left_padding = 6;
            this.buttons_alignment.set_valign (Gtk.Align.FILL);
            this.tweet_box.pack_start (this.buttons_alignment, true, true, 0);

            // buttons box
            this.buttons_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.buttons_box.set_valign (Gtk.Align.FILL);
            this.buttons_alignment.add (this.buttons_box);

            // time label
            this.time_label = new Gtk.Label ("");
            this.time_label.set_halign (Gtk.Align.END);
            this.time_label.set_valign (Gtk.Align.START);
            this.time_label.margin_bottom = 6;
            this.buttons_box.pack_start (this.time_label, true, true, 0);
            this.update_date ();

            // favorite button
            if (!this.tweet.dm) {
                this.favorite_button = new Gtk.Button ();
                this.favorite_button.set_halign (Gtk.Align.END);
                this.favorite_icon = new Gtk.Image.from_icon_name ("twitter-fav", Gtk.IconSize.MENU);
                this.favorite_button.child = this.favorite_icon;
                this.favorite_button.set_tooltip_text (_("Favorite"));
                this.buttons_box.pack_start (favorite_button, false, true, 0);

                this.favorite_button.clicked.connect (() => {
                    this.favorite_button.set_sensitive (false);
                    new Thread<void*> (null, this.favorite_thread);
		        });

		        if (this.tweet.favorited) {
                    this.favorite_icon.set_from_icon_name ("twitter-favd", Gtk.IconSize.MENU);
                }
		    }

            // retweet button
            if (this.tweet.user_screen_name != this.birdie.api.account.screen_name) {
                if (!this.tweet.dm) {
                    this.retweet_button = new Gtk.Button ();
                    this.retweet_button.set_halign (Gtk.Align.END);
                    this.retweet_icon = new Gtk.Image.from_icon_name ("twitter-retweet", Gtk.IconSize.MENU);
                    this.retweet_button.child = this.retweet_icon;
                    if (birdie.service == 0)
                        this.retweet_button.set_tooltip_text (_("Retweet"));
                    else
                        this.retweet_button.set_tooltip_text (_("Repeat"));
                    this.buttons_box.pack_start (retweet_button, false, true, 0);

                    if (this.tweet.retweeted) {
                        this.retweet_button.set_sensitive (false);
                        this.retweet_icon.set_from_icon_name ("twitter-retweeted", Gtk.IconSize.MENU);
                    }

                    this.retweet_button.clicked.connect (() => {
                        this.retweet_button.set_sensitive (false);
			            new Thread<void*> (null, this.retweet_thread);
		            });
		        }

                // reply button
                this.reply_button = new Gtk.Button ();
                this.reply_button.set_halign (Gtk.Align.END);
                this.reply_icon = new Gtk.Image.from_icon_name ("twitter-reply", Gtk.IconSize.MENU);
                this.reply_button.child = this.reply_icon;
                this.reply_button.set_tooltip_text (_("Reply"));

                this.reply_button.clicked.connect (() => {
			        Widgets.TweetDialog dialog = new TweetDialog (this.birdie, this.tweet.id, this.tweet.user_screen_name, this.tweet.dm);
			        dialog.show_all ();
		        });

                this.buttons_box.pack_start (this.reply_button, false, true, 0);
		    } else {
                // delete button
                this.delete_button = new Gtk.Button ();
                this.delete_button.set_halign (Gtk.Align.END);
                this.delete_icon = new Gtk.Image.from_icon_name ("twitter-delete", Gtk.IconSize.MENU);
                this.delete_button.child = this.delete_icon;
                this.delete_button.set_tooltip_text (_("Delete"));

                this.delete_button.clicked.connect (() => {
			        this.delete_button.set_sensitive (false);
			        new Thread<void*> (null, this.delete_thread);
		        });
                this.buttons_box.pack_start (delete_button, false, true, 0);
		    }
            this.set_size_request (-1, 150);
        }

        private void* favorite_thread () {
            int code;

			if (this.tweet.favorited) {
			    code = this.birdie.api.favorite_destroy (this.tweet.id);

			    Idle.add( () => {
			        if (code == 0) {
			            this.tweet.favorited = false;
			            this.birdie.home_list.update_display (this.tweet);
			            this.birdie.mentions_list.update_display (this.tweet);
			            this.birdie.own_list.update_display (this.tweet);
			            this.birdie.favorites.remove (this.tweet);
			        }

			        return false;
			    });

			    this.favorite_button.set_sensitive (true);

			} else {
			    code = this.birdie.api.favorite_create (this.tweet.id);

			    Idle.add( () => {
			        if (code == 0) {
			            this.tweet.favorited = true;
			            this.birdie.home_list.update_display (this.tweet);
			            this.birdie.mentions_list.update_display (this.tweet);
			            this.birdie.own_list.update_display (this.tweet);
			            this.birdie.favorites.append (this.tweet, this.birdie);
			        }

			        this.favorite_button.set_sensitive (true);

			        return false;
			    });
			}
            return null;
        }

        private void* retweet_thread () {
            int code = this.birdie.api.retweet (this.tweet.id);

			Idle.add( () => {
			    if (code == 0) {
			        this.retweet_icon.set_from_icon_name ("twitter-retweeted", Gtk.IconSize.MENU);
			    } else {
			        this.retweet_button.set_sensitive (true);
			    }
			    return false;
			});

            return null;
        }

        private void* delete_thread () {
            int code = this.birdie.api.destroy (this.tweet.id);

			Idle.add( () => {
			    if (code == 0) {
			        this.birdie.home_list.remove (this.tweet);
			        this.birdie.mentions_list.remove (this.tweet);
			        this.birdie.own_list.remove (this.tweet);
			    } else {
			        this.delete_button.set_sensitive (true);
			    }

			    return false;
			});

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

            Idle.add ( () => {
                this.time_label.set_markup ("<span color='#aaaaaa'>" + this.date + "</span>");
                return false;
            });
        }

        public void update_display () {
            if (this.tweet.favorited) {
                this.favorite_icon.set_from_icon_name ("twitter-favd", Gtk.IconSize.MENU);
			    this.favorite_button.set_tooltip_text (_("Unfavorite"));
            } else {
                this.favorite_icon.set_from_icon_name ("twitter-fav", Gtk.IconSize.MENU);
			    this.favorite_button.set_tooltip_text (_("Favorite"));
            }
        }

        private void set_footer () {
            var retweeted_by_label = "";
            
            retweeted_by_label = ("<span color='#aaaaaa'>" + _("retweeted by %s").printf ("<span underline='none'><a href='birdie://user/" + this.tweet.retweeted_by + "'>" + this.tweet.retweeted_by_name + "</a></span>") + "</span>");
            if (this.tweet.retweeted_by != "") {
                var retweeted_img = new Gtk.Image ();
                retweeted_img.set_from_icon_name ("twitter-retweet", Gtk.IconSize.MENU);
                var retweeted_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                this.info_label = new Gtk.Label ("");
                this.info_label.set_halign (Gtk.Align.START);
                if (birdie.service == 1)
                    retweeted_by_label = ("<span color='#aaaaaa'>" + _("repeated by %s").printf ("<span underline='none'><a href='birdie://user/" + this.tweet.retweeted_by + "'>" + this.tweet.retweeted_by_name + "</a></span>") + "</span>");
                this.info_label.set_markup ("<span color='#aaaaaa'>" + retweeted_by_label + "</span>");
                retweeted_box.pack_start (retweeted_img, false, false, 0);
                retweeted_box.pack_start (this.info_label, false, false, 0);
                retweeted_box.margin_top = 6;
                this.content_box.add (retweeted_box);
            } else if (this.tweet.in_reply_to_screen_name != "") {
                var reply_img = new Gtk.Image ();
                reply_img.set_from_icon_name ("twitter-reply", Gtk.IconSize.MENU);
                var reply_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                this.info_label = new Gtk.Label ("");
                this.info_label.set_halign (Gtk.Align.START);               
                var in_reply_label = ("<span color='#aaaaaa'>" + _("in reply to @%s").printf ("<span underline='none'><a href='birdie://user/" + this.tweet.in_reply_to_screen_name + "'>" + this.tweet.in_reply_to_screen_name + "</a></span>") + "</span>");
                this.info_label.set_markup (in_reply_label);
                reply_box.pack_start (reply_img, false, false, 0);
                reply_box.pack_start (this.info_label, false, false, 0);
                reply_box.margin_top = 6;
                this.content_box.add (reply_box);
            } else {
            }
        }

        public void set_selectable (bool select) {
            this.tweet_label.set_selectable (select);
        }
    }
}
