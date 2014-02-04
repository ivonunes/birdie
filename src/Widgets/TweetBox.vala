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

    public class TweetBox : Gtk.EventBox {
        public Tweet tweet;
        public Birdie birdie;

        private Gtk.Box thread_box;
        private Gtk.Box tweet_box;
        private Gtk.Alignment avatar_alignment;
        private Gtk.Alignment content_alignment;
        private Gtk.Alignment buttons_alignment;
        private Gtk.Alignment media_alignment;
        private Gtk.Box content_box;
        private Gtk.EventBox username_event;
        private Gtk.Label username_label;
        private Gtk.Label tweet_label;
        private Gtk.Label info_label;
        private Gtk.Label time_label;
        private Gtk.Box avatar_box;
        private Gtk.EventBox avatar_event;
        private Gtk.Box header_box;
        private Gtk.Box buttons_box;
        private Gtk.Overlay context_overlay;
        private Gtk.Button thread_button;
        private Gtk.Button favorite_button;
        private Gtk.Button retweet_button;
        private Gtk.Button reply_button;
        private Gtk.Button delete_button;
        private Gtk.Button dm_delete_button;
        private Gtk.Image thread_icon;
        private Gtk.Image favorite_icon;
        private Gtk.Image retweet_icon;
        private Gtk.Image reply_icon;
        private Gtk.Image delete_icon;
        private Gtk.Image dm_delete_icon;
        private Gtk.Image avatar_img;
        private Gtk.Image status_img;
        private Gtk.EventBox media_box;
        private Gtk.Image media;
        private Gdk.Pixbuf media_pixbuf;
        private Gtk.Image verified_img;

        private Gtk.Menu rightclick_menu;

        private int year;
        private int month;
        private int day;
        private int hour;
        private int minute;
        private int second;

        private string date;
        public string list_id;
        public string list_owner;

        public TweetBox (Tweet tweet, Birdie birdie, bool inside_thread = false, string list_id = "", string list_owner = "") {

            this.birdie = birdie;
            this.tweet = tweet;
            this.list_id = list_id;
            this.list_owner = list_owner;

            this.hour = 0;
            this.minute = 0;
            this.second = 0;
            this.day = 0;
            this.month = 0;
            this.year = 0;

            set_events (Gdk.EventMask.BUTTON_RELEASE_MASK);

            // thread box
            this.thread_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.add (this.thread_box);

            // tweet box
            this.tweet_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.thread_box.pack_end (this.tweet_box, true, true, 0);

            // avatar alignment
            this.avatar_alignment = new Gtk.Alignment (0,0,0,1);
            this.avatar_alignment.top_padding = 12;
            this.avatar_alignment.right_padding = 4;
            this.avatar_alignment.bottom_padding = 12;
            this.avatar_alignment.left_padding = 12;
            this.tweet_box.pack_start (this.avatar_alignment, false, true, 0);

            // avatar box
            this.avatar_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.avatar_alignment.add (this.avatar_box);

            // Overlay
            this.context_overlay = new Gtk.Overlay ();
            this.tweet_box.pack_start (this.context_overlay, true, true, 0);

            // content alignment
            this.content_alignment = new Gtk.Alignment (0,0,0,1);
            this.content_alignment.top_padding = 12;
            this.content_alignment.right_padding = 12;
            this.content_alignment.bottom_padding = 12;
            this.content_alignment.left_padding = 4;
            this.content_alignment.xscale = 1;
            this.content_alignment.set_valign (Gtk.Align.START);
            this.context_overlay.add (this.content_alignment);

            // content box
            this.content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
            this.content_alignment.add (this.content_box);

            // set info header
            this.set_info_header ();

            // avatar image
            this.avatar_img = new Gtk.Image ();
            this.avatar_img.set_from_file (Constants.PKGDATADIR + "/default.png");
            this.avatar_img.set_halign (Gtk.Align.START);
            this.avatar_img.set_valign (Gtk.Align.START);
            this.avatar_event = new Gtk.EventBox ();
            this.avatar_event.add (this.avatar_img);
            this.avatar_box.pack_start (this.avatar_event, false, false, 0);

            this.avatar_event.button_release_event.connect ((event) => {
                this.birdie.user = tweet.user_screen_name;
                this.birdie.show_user.begin ();
                return false;
            });

            this.avatar_event.enter_notify_event.connect ((event) => {
                on_mouse_enter (this, event);
                return false;
            });

            // header box
            this.header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.content_box.pack_start (this.header_box, false, false, 0);
            this.verified_img = new Gtk.Image ();

            // show symbols properly in user label
            if ("&" in tweet.user_name)
                tweet.user_name = tweet.user_name.replace ("&", "&amp;");

            if (tweet.verified) {
                this.verified_img = new Gtk.Image ();
                this.verified_img.set_from_icon_name ("twitter-verified", Gtk.IconSize.MENU);
                this.verified_img.set_halign (Gtk.Align.END);
                this.header_box.pack_start (this.verified_img, false, true, 0);
            }

            // user label
            this.set_username_label ();

            //FIXME: Set ellipsis mode
            this.header_box.pack_start (this.username_event, false, true, 0);

            // time label
            this.time_label = new Gtk.Label ("");
            this.time_label.set_halign (Gtk.Align.END);
            this.time_label.set_valign (Gtk.Align.START);
            this.update_date ();
            this.header_box.pack_start (this.time_label, true, true, 0);

            // tweet
            this.tweet_label = new Gtk.Label (tweet.text);
            this.tweet_label.set_use_markup (true);
            this.tweet_label.set_selectable (true);
            this.tweet_label.set_line_wrap (true);
            this.tweet_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
            this.tweet_label.set_halign (Gtk.Align.START);
            this.tweet_label.set_valign (Gtk.Align.START);
            this.tweet_label.xalign = 0;
            this.content_box.pack_start (this.tweet_label, false, true, 0);

            // css
            Gtk.StyleContext ctx = this.tweet_label.get_style_context ();
            ctx.add_class("tweet");

            // media
            this.set_media ();

            // rightclick menu
            this.rightclick_menu = new Gtk.Menu ();

            var browser_menu_item = new Gtk.MenuItem.with_label (_("Open in browser"));
            this.rightclick_menu.append (browser_menu_item);
            browser_menu_item.show ();

            var link_menu_item = new Gtk.MenuItem.with_label (_("Copy link"));
            this.rightclick_menu.append (link_menu_item);
            link_menu_item.show ();

            browser_menu_item.activate.connect (() => {
                try {
                    GLib.Process.spawn_command_line_async ("xdg-open http://www.twitter.com/" + tweet.user_screen_name + "/status/" + tweet.id);
                } catch (Error e) {
                }
            });

            link_menu_item.activate.connect (() => {
                var clipboard = Gtk.Clipboard.get_for_display (this.birdie.m_window.get_display (), Gdk.SELECTION_CLIPBOARD);
                clipboard.set_text ("http://www.twitter.com/" + tweet.user_screen_name + "/status/" + tweet.id, -1);
            });

            // status image
            this.status_img = new Gtk.Image ();
            this.status_img.set_halign (Gtk.Align.END);
            this.status_img.set_valign (Gtk.Align.START);

            if ((this.tweet.favorited || this.tweet.retweeted) && !this.tweet.dm)
                this.context_overlay.add_overlay (this.status_img);

            // buttons alignment
            this.buttons_alignment = new Gtk.Alignment (0, 0, 0, 1);
            this.buttons_alignment.set_halign (Gtk.Align.END);
            this.buttons_alignment.set_valign (Gtk.Align.START);
            this.buttons_alignment.top_padding = 6;
            this.buttons_alignment.right_padding = 6;
            this.context_overlay.add_overlay (this.buttons_alignment);

            // buttons box
            this.buttons_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            this.buttons_box.set_halign (Gtk.Align.END);
            this.buttons_box.set_valign (Gtk.Align.START);
            this.buttons_box.set_no_show_all (true);
            this.buttons_box.hide ();

            // set buttons
            this.set_thread_btn (inside_thread);
            this.set_favorite_btn ();
            this.set_retweet_btn ();
            this.set_delete_btn ();
        }

        public virtual void on_mouse_enter (Gtk.Widget widget, Gdk.EventCrossing event) {
            event.window.set_cursor (
                new Gdk.Cursor.from_name (Gdk.Display.get_default(), "hand2")
            );
        }

        private void* thread_thread () {
            var spinner = new Gtk.Spinner ();

            Idle.add ( () => {
                this.thread_box.pack_start (spinner, false, false, 0);
                spinner.start ();
                spinner.show ();
                return false;
            });

            string parsing_id = this.tweet.in_reply_to_status_id;

            List<Tweet> tweets = new List<Tweet> ();

            for (int i = 0; i < 5; i++) {
                var tweet = this.birdie.api.get_single_tweet (parsing_id);

                tweets.append (tweet);

                if (tweet.in_reply_to_status_id != "")
                    parsing_id = tweet.in_reply_to_status_id;
                else
                    break;
            }

            tweets.reverse ();
            tweets.foreach ((tweet) => {
                var tweet_box = new TweetBox (tweet, this.birdie, true);
                Media.get_single_avatar.begin (tweet_box);

                Idle.add ( () => {
                    this.thread_box.pack_start (tweet_box, false, false, 0);
                    tweet_box.show_all ();
                    return false;
                });
            });

            Idle.add ( () => {
                spinner.stop ();
                spinner.hide ();
                this.thread_box.remove (spinner);
                spinner.destroy ();
                return false;
            });

            return null;
        }

        private void* favorite_thread () {
            int code;

            if (this.tweet.favorited) {
                Idle.add( () => {
                    if (this.tweet.retweeted) {
                        this.status_img.set_from_icon_name("twitter-ret-banner",  Gtk.IconSize.LARGE_TOOLBAR);
                    } else {
                        this.context_overlay.remove (this.status_img);
                    }

                    this.tweet.favorited = false;
                    this.birdie.favorites.remove (this.tweet);

                    this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "favorites");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 0, "tweets");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 0, "own");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 0, "mentions");

                    return false;
                });
                code = this.birdie.api.favorite_destroy (this.tweet.actual_id);

                if (code == 1) {
                    this.tweet.favorited = true;
                    this.birdie.db.add_tweet.begin (this.tweet, "favorites", this.birdie.default_account_id);
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 1, "tweets");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 1, "own");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 1, "mentions");
                }
            } else {
                Idle.add( () => {
                    if (this.tweet.retweeted) {
                        this.status_img.set_from_icon_name ("twitter-favret-banner", Gtk.IconSize.LARGE_TOOLBAR);
                    } else {
                        this.context_overlay.remove (this.buttons_alignment);
                        this.status_img.set_from_icon_name("twitter-fav-banner",  Gtk.IconSize.LARGE_TOOLBAR);
                        this.context_overlay.add_overlay (this.status_img);
                        this.context_overlay.add_overlay (this.buttons_alignment);
                        this.status_img.show ();
                    }

                    this.tweet.favorited = true;

                    this.birdie.favorites.append (this.tweet, this.birdie);

                    this.birdie.db.add_tweet.begin (this.tweet, "favorites", this.birdie.default_account_id);
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 1, "tweets");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 1, "own");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 1, "mentions");
                    Media.get_avatar (this.birdie.favorites);

                    return false;
                });
                code = this.birdie.api.favorite_create (this.tweet.actual_id);

                if (code == 1) {
                    this.birdie.favorites.remove (this.tweet);
                    this.tweet.favorited = false;
                    this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "favorites");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 0, "tweets");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 0, "own");
                    this.birdie.db.set_favorite (this.tweet.actual_id, this.birdie.default_account_id, 0, "mentions");
                }
            }

            Idle.add( () => {
                this.favorite_button.set_sensitive (true);
                // update this timeline ui
                this.birdie.home_list.update_display (this.tweet, true);
                this.birdie.mentions_list.update_display (this.tweet, true);
                this.birdie.own_list.update_display (this.tweet, true);

                //TODO: update other timelines boxes ui to reflect favorite status changes on the current one

                return false;
            });

            return null;
        }

        private void set_thread_btn (bool inside_thread) {
            // thread button
            if (!this.tweet.dm) {
                if (this.tweet.in_reply_to_status_id != "" && !inside_thread) {
                    this.thread_button = new Gtk.Button ();
                    this.thread_button.set_halign (Gtk.Align.END);
                    this.thread_button.set_relief (Gtk.ReliefStyle.NONE);
                    this.thread_icon = new Gtk.Image.from_icon_name ("twitter-thread", Gtk.IconSize.SMALL_TOOLBAR);
                    this.thread_button.child = this.thread_icon;
                    this.thread_button.set_tooltip_text (_("Thread"));
                    this.buttons_box.pack_start (thread_button, false, true, 0);

                    this.thread_button.clicked.connect (() => {
                        this.thread_button.set_sensitive (false);
                        new Thread<void*> (null, this.thread_thread);
                    });
                }
            }
        }

        private void* retweet_thread () {
            int code;

            Idle.add( () => {
                if (this.tweet.favorited) {
                    this.status_img.set_from_icon_name("twitter-favret-banner",  Gtk.IconSize.LARGE_TOOLBAR);
                } else {
                    this.context_overlay.remove (this.buttons_alignment);

                    this.status_img.set_from_icon_name("twitter-ret-banner",  Gtk.IconSize.LARGE_TOOLBAR);

                    this.context_overlay.add_overlay (this.status_img);
                    this.context_overlay.add_overlay (this.buttons_alignment);
                    this.status_img.show ();
                }

                this.retweet_icon.set_from_icon_name ("twitter-retweeted", Gtk.IconSize.SMALL_TOOLBAR);
                this.tweet.retweeted = true;
                return false;
            });
            code = this.birdie.api.retweet (this.tweet.id);
            return null;
        }

        private void* delete_thread () {
            if (this.list_id != "") {
                this.birdie.api.remove_from_list (this.list_id, this.tweet.user_screen_name);

                Idle.add( () => {
                    this.birdie.list_list.remove_by_user (this.tweet.user_screen_name);
                    return false;
                });
            } else {
                int code;

                Idle.add( () => {
                    this.birdie.home_list.remove (this.tweet);
                    this.birdie.mentions_list.remove (this.tweet);
                    this.birdie.own_list.remove (this.tweet);
                    this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "own");
                    this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "tweets");
                    this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "mentions");
                    return false;
                });

                code = this.birdie.api.destroy (this.tweet.actual_id);
            }

            return null;
        }

        private void* delete_dm_thread () {
            int code;

            Idle.add( () => {
                this.birdie.dm_list.remove (this.tweet);
                this.birdie.dm_sent_list.remove (this.tweet);
                this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "dm_inbox");
                this.birdie.db.remove_status (this.tweet.actual_id, this.birdie.default_account_id, "dm_outbox");
                return false;
            });
            code = this.birdie.api.destroy_dm (this.tweet.actual_id);
            return null;
        }

        private void set_favorite_btn () {
            // favorite button
            if (!this.tweet.dm) {
                this.favorite_button = new Gtk.Button ();
                this.favorite_button.set_halign (Gtk.Align.END);
                this.favorite_button.set_relief (Gtk.ReliefStyle.NONE);
                this.favorite_icon = new Gtk.Image.from_icon_name ("twitter-fav", Gtk.IconSize.SMALL_TOOLBAR);
                this.favorite_button.child = this.favorite_icon;
                this.favorite_button.set_tooltip_text (_("Favorite"));
                this.buttons_box.pack_start (favorite_button, false, true, 0);

                this.favorite_button.clicked.connect (() => {
                    this.favorite_button.set_sensitive (false);
                    new Thread<void*> (null, this.favorite_thread);
                });

                if (this.tweet.favorited) {
                    this.favorite_icon.set_from_icon_name ("twitter-favd", Gtk.IconSize.SMALL_TOOLBAR);
                    this.status_img.set_from_icon_name("twitter-fav-banner",  Gtk.IconSize.LARGE_TOOLBAR);
                }
            }
        }

        private void set_retweet_btn () {
            // retweet button
            if (this.tweet.user_screen_name != this.birdie.api.account.screen_name) {
                if (!this.tweet.dm) {
                    this.retweet_button = new Gtk.Button ();
                    this.retweet_button.set_halign (Gtk.Align.END);
                    this.retweet_button.set_relief (Gtk.ReliefStyle.NONE);
                    this.retweet_icon = new Gtk.Image.from_icon_name ("twitter-retweet", Gtk.IconSize.SMALL_TOOLBAR);
                    this.retweet_button.child = this.retweet_icon;
                    this.retweet_button.set_tooltip_text (_("Retweet"));
                    this.buttons_box.pack_start (retweet_button, false, true, 0);

                    if (this.tweet.retweeted) {
                        this.retweet_button.set_sensitive (false);
                        this.retweet_icon.set_from_icon_name ("twitter-retweeted", Gtk.IconSize.SMALL_TOOLBAR);
                        this.status_img.set_from_icon_name ("twitter-ret-banner",  Gtk.IconSize.LARGE_TOOLBAR);
                    }

                    this.retweet_button.clicked.connect (() => {
                        this.retweet_button.set_sensitive (false);
                        new Thread<void*> (null, this.retweet_thread);
                    });

                    // show more options when right clicking the button
                    var retweet_quote_menu_item = new Gtk.MenuItem.with_label (_("Retweet with quote"));
                    this.rightclick_menu.append (retweet_quote_menu_item);
                    retweet_quote_menu_item.show ();

                    retweet_quote_menu_item.activate.connect (() => {
                        Widgets.TweetDialog dialog = new TweetDialog (this.birdie, this.tweet.id,
                            "RT @" + this.tweet.user_screen_name + ": \"" + Utils.remove_html_tags (this.tweet.text) + "\"", this.tweet.dm);
                        dialog.show_all ();
                    });
                }

                if (this.tweet.retweeted && this.tweet.favorited) {
                        this.status_img.set_from_icon_name ("twitter-favret-banner",  Gtk.IconSize.LARGE_TOOLBAR);
                    }

                if (!this.tweet.dm || (this.tweet.dm && this.tweet.user_name != this.birdie.api.account.name)) {
                    // reply button
                    this.reply_button = new Gtk.Button ();
                    this.reply_button.set_halign (Gtk.Align.END);
                    this.reply_button.set_relief (Gtk.ReliefStyle.NONE);
                    this.reply_icon = new Gtk.Image.from_icon_name ("twitter-reply", Gtk.IconSize.SMALL_TOOLBAR);
                    this.reply_button.child = this.reply_icon;
                    this.reply_button.set_tooltip_text (_("Reply"));

                    this.reply_button.clicked.connect (() => {
                        Widgets.TweetDialog dialog = new TweetDialog (this.birdie, this.tweet.id, this.tweet.user_screen_name, this.tweet.dm);
                        dialog.show_all ();
                    });

                    this.buttons_box.pack_start (this.reply_button, false, true, 0);
                }
                if (this.tweet.dm) {
                    // dm delete button
                    this.dm_delete_button = new Gtk.Button ();
                    this.dm_delete_button.set_halign (Gtk.Align.END);
                    this.dm_delete_button.set_relief (Gtk.ReliefStyle.NONE);
                    this.dm_delete_icon = new Gtk.Image.from_icon_name ("twitter-delete", Gtk.IconSize.SMALL_TOOLBAR);
                    this.dm_delete_button.child = this.dm_delete_icon;
                    this.dm_delete_button.set_tooltip_text (_("Delete"));

                    this.dm_delete_button.clicked.connect (() => {
                        // confirm deletion
                        Widgets.AlertDialog confirm = new Widgets.AlertDialog (this.birdie.m_window,
                            Gtk.MessageType.QUESTION, _("Delete this direct message?"),
                            _("Delete"), _("Cancel"));
                        Gtk.ResponseType response = confirm.run ();
                        if (response == Gtk.ResponseType.OK) {
                            this.dm_delete_button.set_sensitive (false);
                            new Thread<void*> (null, this.delete_dm_thread);
                        }
                    });
                    this.buttons_box.pack_start (this.dm_delete_button, false, true, 0);
                }
            }
        }

        private void set_delete_btn () {
            if (this.tweet.user_screen_name == this.birdie.api.account.screen_name ||
                (this.list_id != "" && this.birdie.api.account.screen_name == this.list_owner)) {
                // delete button
                this.delete_button = new Gtk.Button ();
                this.delete_button.set_halign (Gtk.Align.END);
                this.delete_button.set_relief (Gtk.ReliefStyle.NONE);
                this.delete_icon = new Gtk.Image.from_icon_name ("twitter-delete", Gtk.IconSize.SMALL_TOOLBAR);
                this.delete_button.child = this.delete_icon;
                this.delete_button.set_tooltip_text (_("Delete"));

                this.delete_button.clicked.connect (() => {
                    // confirm deletion
                    Widgets.AlertDialog confirm;

                    if (this.list_id != "") {
                        confirm = new Widgets.AlertDialog (this.birdie.m_window,
                        Gtk.MessageType.QUESTION, _("Remove user from list?"),
                        _("Remove"), _("Cancel"));
                    } else {
                        confirm = new Widgets.AlertDialog (this.birdie.m_window,
                        Gtk.MessageType.QUESTION, _("Delete this tweet?"),
                        _("Delete"), _("Cancel"));
                    }

                    Gtk.ResponseType response = confirm.run ();
                    if (response == Gtk.ResponseType.OK) {
                        this.delete_button.set_sensitive (false);
                        new Thread<void*> (null, this.delete_thread);
                    }
                });
                this.buttons_box.pack_start (delete_button, false, true, 0);
            }

            this.buttons_alignment.add (this.buttons_box);

            set_events(Gdk.EventMask.BUTTON_RELEASE_MASK);
            set_events(Gdk.EventMask.ENTER_NOTIFY_MASK);
            set_events(Gdk.EventMask.LEAVE_NOTIFY_MASK);

            this.button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_SECONDARY)
                    this.rightclick_menu.popup (null, null, null, e.button, e.time);

                return false;
            });

            this.enter_notify_event.connect ((event) => {
                this.show_buttons ();
                return false;
            });

            this.leave_notify_event.connect ((event) => {
                Gtk.Allocation allocation;
                this.get_allocation (out allocation);

                if (event.x < 0 || event.x >= allocation.width ||
                    event.y < 0 || event.y >= allocation.height) {
                        this.hide_buttons ();
                }
                return false;
            });
        }

        public void hide_buttons () {
            this.buttons_box.hide ();
            this.time_label.show ();
        }

        public void show_buttons () {
            this.buttons_box.set_no_show_all (false);
            this.buttons_box.show_all ();
            this.buttons_box.set_no_show_all (true);
            this.time_label.hide ();
        }

        private void set_username_label () {
            this.username_label = new Gtk.Label ("");
            this.username_label.set_halign (Gtk.Align.START);
            this.username_label.set_valign (Gtk.Align.START);
            this.username_label.set_selectable (false);
            this.username_label.set_markup (
                "<span underline='none' font_weight='bold' size='large'>" +
                tweet.user_name.chomp () +
                "</span> <span font_weight='light' color='#999'>@" +
                tweet.user_screen_name + "</span>"
                );

            this.username_event = new Gtk.EventBox ();
            this.username_event.add (this.username_label);

            this.username_event.button_release_event.connect ((event) => {
                this.birdie.user = tweet.user_screen_name;
                this.birdie.show_user.begin ();
                return false;
            });

            this.username_event.enter_notify_event.connect ((event) => {
                on_mouse_enter (this, event);
                return false;
            });
        }

        private void set_media () {
            if (tweet.media_url != "" || tweet.youtube_video != "") {
                string filename;
                bool placeholder = false;

                if (tweet.media_url != "") {
                    filename = this.tweet.media_url;
                } else {
                    filename = "youtube_" + this.tweet.youtube_video + ".jpg";
                }

                GLib.File file = File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/media/" + filename);

                if (file.query_exists ()) {
                    try {
                        media_pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                            Environment.get_home_dir () + "/.cache/birdie/media/" + filename,
                            325, 325, true);
                    } catch (Error e) { placeholder = true; }
                } else {
                    placeholder = true;

                    try {
                    media_pixbuf = new Gdk.Pixbuf.from_file_at_scale (
                        Constants.PKGDATADIR + "/media.png",
                        325, 325, true);
                    } catch (Error e) { }
                }

                this.media = new Gtk.Image.from_pixbuf (media_pixbuf);
                this.media.set_halign (Gtk.Align.START);
                this.media_box = new Gtk.EventBox ();

                this.media_alignment = new Gtk.Alignment (0, 0, 0, 1);
                this.media_alignment.set_halign (Gtk.Align.START);
                this.media_alignment.set_valign (Gtk.Align.START);
                this.media_alignment.top_padding = 6;
                this.media_box.add (this.media);
                this.media_alignment.add (this.media_box);
                this.content_box.pack_start (this.media_alignment, false, false, 0);
                this.set_media_events ();

                if (placeholder)
                    this.media_box.set_no_show_all (true);
            }
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
                this.time_label.set_markup ("<span color='#999aaa'>" + this.date + "</span>");
                return false;
            });
        }

        public void update_favorites () {
            if (this.tweet.favorited) {
                Idle.add (() => {
                    this.favorite_icon.set_from_icon_name ("twitter-favd", Gtk.IconSize.SMALL_TOOLBAR);
                    this.favorite_button.set_tooltip_text (_("Unfavorite"));
                    return false;
                });
            } else {
                Idle.add (() => {
                    this.favorite_icon.set_from_icon_name ("twitter-fav", Gtk.IconSize.SMALL_TOOLBAR);
                    this.favorite_button.set_tooltip_text (_("Favorite"));
                    return false;
                });
            }
        }

        public void update_media () {
            if (this.tweet.youtube_video != "") {
                var file = File.new_for_path (Environment.get_home_dir () +
                                "/.cache/birdie/media/youtube_" +
                                this.tweet.youtube_video + ".jpg");

                if (file.query_exists ()) {
                    Idle.add (() => {
                        try {
                            this.media.set_from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (
                                    Environment.get_home_dir () +
                                    "/.cache/birdie/media/youtube_" +
                                    this.tweet.youtube_video + ".jpg",
                                    325, 325, true
                                    ));
                            this.media_box.set_no_show_all (false);
                            this.media_box.show_all ();
                        } catch {}
                    return false;
                    });
                }
            }
            else if (this.tweet.media_url != "") {
                var file = File.new_for_path (Environment.get_home_dir () + "/.cache/birdie/media/" + this.tweet.media_url);

                if (file.query_exists ()) {
                    Idle.add (() => {

                        try {
                            this.media.set_from_pixbuf (new Gdk.Pixbuf.from_file_at_scale (
                                    Environment.get_home_dir () + "/.cache/birdie/media/" + this.tweet.media_url,
                                    325, 325, true
                                    ));
                            this.media_box.set_no_show_all (false);
                            this.media_box.show_all ();
                        } catch {}
                    return false;
                    });
                }
            }
            this.avatar_img.set_from_file (Environment.get_home_dir () + "/.cache/birdie/" + this.tweet.profile_image_file);
        }

        private void set_media_events () {
            this.media_box.enter_notify_event.connect ((event) => {
                on_mouse_enter (this, event);
                return false;
            });

            this.media_box.button_release_event.connect ((event) => {
                if (this.tweet.youtube_video != "")
                    Media.show_youtube_video (this.tweet.youtube_video);
                else
                    Media.show_media (this.tweet.media_url);
                return false;
            });
        }

        private void set_info_header () {
            var retweeted_by_label = "";

            retweeted_by_label = ("<span color='#999'>" +
                _("retweeted by %s").printf ("<span underline='none'><a href='birdie://user/" +
                this.tweet.retweeted_by + "'>" + this.tweet.retweeted_by_name +
                "</a></span>") + "</span>");

            if (this.tweet.retweeted_by != "") {
                var retweeted_img = new Gtk.Image ();
                retweeted_img.set_from_icon_name ("twitter-retweet", Gtk.IconSize.MENU);
                retweeted_img.set_halign (Gtk.Align.END);
                retweeted_img.margin_bottom = 6;
                this.info_label = new Gtk.Label ("");
                this.info_label.set_halign (Gtk.Align.START);
                this.info_label.margin_bottom = 6;
                this.info_label.set_markup ("<span color='#999'>" + retweeted_by_label + "</span>");
                avatar_box.pack_start (retweeted_img, false, false, 0);
                content_box.pack_start (this.info_label, false, false, 0);

            } else if (this.tweet.in_reply_to_screen_name != "" && this.tweet.in_reply_to_status_id != "") {
                var reply_img = new Gtk.Image ();
                reply_img.set_from_icon_name ("twitter-reply", Gtk.IconSize.MENU);
                reply_img.set_halign (Gtk.Align.END);
                reply_img.margin_bottom = 6;
                this.info_label = new Gtk.Label ("");
                this.info_label.set_halign (Gtk.Align.START);
                this.info_label.margin_bottom = 6;
                var in_reply_label = ("<span color='#999'>" +
                    _("in reply to @%s").printf ("<span underline='none'><a href='birdie://user/" +
                    this.tweet.in_reply_to_screen_name + "'>" +
                    this.tweet.in_reply_to_screen_name + "</a></span>") + "</span>");

                this.info_label.set_markup (in_reply_label);
                avatar_box.pack_start (reply_img, false, false, 0);
                content_box.pack_start (this.info_label, false, false, 0);
            } else {
            }
        }

        public void set_selectable (bool select) {
            this.tweet_label.set_selectable (select);
        }

        public void set_avatar (string avatar_file) {
            Idle.add (() => {
                var file = File.new_for_path (avatar_file);

                if (file.query_exists ())
                    this.avatar_img.set_from_file (avatar_file);
                return false;
            });
        }
    }
}