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

namespace Birdie {

    public class Birdie : Granite.Application {
		private Gtk.Box m_box;
        public Widgets.UnifiedWindow m_window;
        public Widgets.TweetList home_list;
        public Widgets.TweetList mentions_list;
        public Widgets.TweetList dm_list;
        public Widgets.TweetList dm_sent_list;
        public Widgets.TweetList own_list;
        public Widgets.TweetList favorites;
        public Widgets.TweetList user_list;
        public Widgets.TweetList search_list;
        public Widgets.ListsView lists;
        public Widgets.TweetList list_list;

        public Gtk.ToolButton new_tweet;
        public Gtk.ToggleToolButton home;
        public Gtk.ToggleToolButton mentions;
        public Gtk.ToggleToolButton dm;
        public Gtk.ToggleToolButton profile;
        private Gtk.Button search;
        private Gtk.Button avatar_button;
        private Gtk.Button new_button;

        private Granite.Widgets.ModeButton switcher;

        private Widgets.UserBox own_box_info;
        private Gtk.Box own_box;

        private Widgets.UserBox user_box_info;
        private Gtk.Box user_box;

        private Gtk.ScrolledWindow scrolled_home;
        private Gtk.ScrolledWindow scrolled_mentions;
        private Gtk.ScrolledWindow scrolled_dm;
        private Gtk.ScrolledWindow scrolled_dm_sent;
        private Gtk.ScrolledWindow scrolled_own;
        private Gtk.ScrolledWindow scrolled_favorites;
        private Gtk.ScrolledWindow scrolled_user;
        private Gtk.ScrolledWindow scrolled_lists;
        private Gtk.ScrolledWindow scrolled_search;
        private Gtk.ScrolledWindow scrolled_list;
        private Gtk.ScrolledWindow scrolled_conversations_list;

        private Widgets.Welcome welcome;
        private Widgets.ErrorPage error_page;

        public Gtk.Stack notebook;
        private Widgets.Notebook notebook_dm;
        public Widgets.Notebook notebook_own;
        private Widgets.Notebook notebook_user;
        private Widgets.ConversationsList conversations_list;
        private Widgets.ConversationView conversation_view;
        private Gtk.Popover search_popover;

        private Gtk.Spinner spinner;

        private GLib.List<Tweet> home_tmp;
        public GLib.List<string> list_members;

        public API api;
        public API new_api;

        public Utils.Notification notification;

        public string current_timeline;

        #if HAVE_LIBUNITY
        private Utils.Launcher launcher;
        #endif

        private Utils.StatusIcon statusIcon;

        private int unread_tweets;
        private int unread_mentions;
        private int unread_dm;

        private bool tweet_notification;
        private bool mention_notification;
        private bool dm_notification;
        private int update_interval;

        public Settings settings;

        public string user;
        private string search_term;
        private string list_id;
        private string list_owner;
        public bool adding_to_list;

        public bool initialized;
        private bool ready;
        private bool changing_tab;
        private bool search_visible;

        public SqliteDatabase db;

        private Cache cache;

        private User default_account;
        public int? default_account_id;

        private uint timerID_online;
        private uint timerID_offline;
        private DateTime timer_date_online;
        private DateTime timer_date_offline;

        private int limit_notifications;

        private Gtk.Revealer accounts_revealer;
        private Gtk.Box accounts_box;
        private signal void exit();

        public static const OptionEntry[] app_options = {
            { "debug", 'd', 0, OptionArg.NONE, out Option.DEBUG, "Enable debug logging", null },
            { "start-hidden", 's', 0, OptionArg.NONE, out Option.START_HIDDEN, "Start hidden", null },
            { null }
        };

        construct {
            program_name        = "Birdie";
            exec_name           = "birdie";
            build_version       = Constants.VERSION;
            app_years           = "2013-2016";
            app_icon            = "birdie";
            app_launcher        = "birdie.desktop";
            application_id      = "org.birdieapp.birdie";
            main_url            = "http://birdieapp.github.io/";
            bug_url             = "https://github.com/birdieapp/birdie/issues";
            help_url            = "https://github.com/birdieapp/birdie/wiki";
            translate_url       = "http://www.transifex.com/projects/p/birdie/";
            about_authors       = {"Ivo Nunes <ivo@elementaryos.org>", "Vasco Nunes <vascomfnunes@gmail.com>", "Nathan Dyer <mail@nathandyer.me>"};
            about_artists       = {"Daniel Foré <daniel@elementaryos.org>", "Mustapha Asbbar"};
            about_comments      = null;
            about_documenters   = {};
            about_translators   = null;
            about_license_type  = Gtk.License.GPL_3_0;
        }

        private Gtk.SearchEntry search_entry;


        public Birdie () {
            GLib.Object(application_id: "org.birdie", flags: ApplicationFlags.HANDLES_OPEN);

            Intl.bindtextdomain ("birdie", Constants.DATADIR + "/locale");

            this.initialized = false;
            this.ready = false;
            this.changing_tab = false;
            this.adding_to_list = false;

            // create cache and db dirs if needed
            Utils.create_dir_with_parents ("/.cache/birdie/media");
            Utils.create_dir_with_parents ("/.local/share/birdie/avatars");

            // init database object
            this.db = new SqliteDatabase ();
            // init cache object
            this.cache = new Cache (this);
        }

        /*

        Activate method

        */

        public override void activate (){
            if (get_windows () == null) {
                Utils.Logger.initialize ("birdie");
                Utils.Logger.DisplayLevel = Utils.LogLevel.INFO;
                message ("Birdie version: %s", Constants.VERSION);
                var un = Posix.utsname ();
                message ("Kernel version: %s", (string) un.release);

                if (Option.DEBUG)
                    Utils.Logger.DisplayLevel = Utils.LogLevel.DEBUG;
                else
                    Utils.Logger.DisplayLevel = Utils.LogLevel.WARN;

                // settings
                this.settings = new Settings ("org.birdieapp.birdie");
                this.tweet_notification = settings.get_boolean ("tweet-notification");
                this.mention_notification = settings.get_boolean ("mention-notification");
                this.dm_notification = settings.get_boolean ("dm-notification");
                this.update_interval = settings.get_int ("update-interval");
                this.limit_notifications = settings.get_int ("limit-notifications");
                this.exit.connect(on_exit);

                Gtk.Window.set_default_icon_name ("birdie");
                this.m_window = new Widgets.UnifiedWindow ();
 
                this.m_window.set_default_size (700, 500);
                this.m_window.set_size_request (700, 50);
                this.m_window.set_application (this);

                // restore main window size and position
                this.m_window.opening_x = settings.get_int ("opening-x");
                this.m_window.opening_y = settings.get_int ("opening-y");
                this.m_window.window_width = settings.get_int ("window-width");
                this.m_window.window_height = settings.get_int ("window-height");
                this.m_window.restore_window ();
                this.m_window.set_size_request(settings.get_int ("window-width"), settings.get_int ("window-height"));

                #if HAVE_LIBUNITY
                this.launcher = new Utils.Launcher (this);
                #endif

                if (settings.get_boolean ("status-icon") && !Utils.is_gnome ())
                    this.statusIcon = new Utils.StatusIcon (this);

                // initialize notifications
                this.notification = new Utils.Notification ();
                this.notification.init ();

                this.unread_tweets = 0;
                this.unread_mentions = 0;
                this.unread_dm = 0;

                this.m_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);

                this.new_tweet = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("twitter-new-tweet-symbolic", Gtk.IconSize.LARGE_TOOLBAR), _("New Tweet"));
                new_tweet.set_tooltip_text (_("New Tweet"));

                // setup keyboard shortcuts
                this.m_window.key_press_event.connect ( (e) => {

                    // Was the control key pressed?
                    if((e.state & Gdk.ModifierType.CONTROL_MASK) != 0) {
                        switch (e.keyval) {
                            case Gdk.Key.q:
                                exit();
                                this.m_window.destroy();
                                break;
                            case Gdk.Key.n:
                                new_tweet.clicked();
                                break;
                            default:
                                break;
                        }
                    }
                    return false;
                });

                new_tweet.clicked.connect (() => {
                    Widgets.TweetDialog dialog = new Widgets.TweetDialog (this, "", "", false);

                    dialog.set_relative_to(new_tweet);
                    dialog.show_all ();
                });

                this.m_window.header.pack_start (new_tweet);

                search_entry = new Gtk.SearchEntry ();
                search_entry.set_width_chars(5);
                search_entry.margin = 12;

                search_entry.activate.connect (() => {
                    this.search_term = ((Gtk.Entry)search_entry).get_text ();
                    this.show_search.begin ();
                });

                switcher = new Granite.Widgets.ModeButton();
                switcher.append_icon("twitter-home-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                switcher.append_icon("twitter-mentions-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                switcher.append_icon("twitter-dm-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

                switcher.mode_changed.connect((widget) => {
                    switch(switcher.selected) {
                        case 0:
                            switch_timeline("home");
                            break;
                        case 1:
                            switch_timeline("mentions");
                            break;
                        case 2:
                            switch_timeline("dm");
                            break;
                    }
                });

                this.m_window.header.set_custom_title (switcher);

                this.search = new Gtk.Button.from_icon_name ("edit-find-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
                search.set_tooltip_text (_("Search"));
                this.search.set_sensitive (false);

                search.clicked.connect(show_search_entry);

                search_popover = new Gtk.Popover(search);
                search_popover.position = Gtk.PositionType.BOTTOM;
                search_popover.add(search_entry);
                
                avatar_button = new Gtk.Button();
                this.m_window.header.pack_end(avatar_button);
                this.m_window.header.pack_end(search);

                /*==========  tweets lists  ==========*/

                this.home_list = new Widgets.TweetList ();
                this.mentions_list = new Widgets.TweetList ();
                this.dm_list = new Widgets.TweetList ();
                this.dm_sent_list = new Widgets.TweetList ();
                this.own_list = new Widgets.TweetList ();
                this.user_list = new Widgets.TweetList ();
                this.favorites = new Widgets.TweetList ();
                this.lists = new Widgets.ListsView(this);
                this.list_list = new Widgets.TweetList ();
                this.search_list = new Widgets.TweetList ();

                /*==========  scrolled widgets  ==========*/

                this.scrolled_home = new Gtk.ScrolledWindow (null, null);
                this.scrolled_home.add_with_viewport (home_list);

                // Automatically load in older tweets when we hit rock bottom
                this.scrolled_home.edge_reached.connect((pos_t) => {
                    if(pos_t == Gtk.PositionType.BOTTOM)
                        get_older_tweets();
                });

                this.scrolled_mentions = new Gtk.ScrolledWindow (null, null);
                this.scrolled_mentions.add_with_viewport (mentions_list);
                this.scrolled_mentions.edge_reached.connect((pos_t) => {
                    if(pos_t == Gtk.PositionType.BOTTOM)
                        get_older_mentions();
                });

                this.scrolled_dm = new Gtk.ScrolledWindow (null, null);
                this.scrolled_dm.add_with_viewport (dm_list);
                this.scrolled_dm_sent = new Gtk.ScrolledWindow (null, null);
                this.scrolled_dm_sent.add_with_viewport (dm_sent_list);

                this.scrolled_own = new Gtk.ScrolledWindow (null, null);

                this.scrolled_favorites = new Gtk.ScrolledWindow (null, null);
                this.scrolled_lists = new Gtk.ScrolledWindow (null, null);
                this.scrolled_lists.add_with_viewport (this.lists);

                this.scrolled_user = new Gtk.ScrolledWindow (null, null);
                this.scrolled_user.add_with_viewport (user_list);

                this.scrolled_list = new Gtk.ScrolledWindow (null, null);
                this.scrolled_list.add_with_viewport (list_list);

                this.scrolled_search = new Gtk.ScrolledWindow (null, null);
                this.scrolled_search.add_with_viewport (search_list);
                this.scrolled_search.edge_reached.connect((pos_t) => {
                    if(pos_t == Gtk.PositionType.BOTTOM)
                        get_older_search();
                });

                this.scrolled_conversations_list = new Gtk.ScrolledWindow (null, null);

                this.welcome = new Widgets.Welcome (this);
                this.error_page = new Widgets.ErrorPage (this);

                this.notebook_dm = new Widgets.Notebook ();
                this.notebook_dm.append_page (this.scrolled_dm, new Gtk.Label (_("Received")));
                this.notebook_dm.append_page (this.scrolled_dm_sent, new Gtk.Label (_("Sent")));

                this.conversations_list = new Widgets.ConversationsList(dm_list, dm_sent_list);
                this.conversations_list.conversation_selected.connect(on_conversation_selected);
                this.conversation_view = new Widgets.ConversationView(this);

                this.scrolled_conversations_list.add_with_viewport(conversations_list);
                
                this.notebook = new Gtk.Stack ();
                this.notebook.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

                this.conversation_view.return_to_conversations_list.connect(() => {
                    this.notebook.set_visible_child(scrolled_conversations_list);
                });

                this.spinner = new Gtk.Spinner ();
                this.spinner.set_size_request (32, 32);
                this.spinner.start ();

                Gtk.Box spinner_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                spinner_box.pack_start (new Gtk.Label (""), true, true, 0);
                spinner_box.pack_start (this.spinner, false, false, 0);
                spinner_box.pack_start (new Gtk.Label (""), true, true, 0);

                this.init_api ();

                this.own_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                this.own_box_info = new Widgets.UserBox ();
                this.own_box.pack_start (this.own_box_info, false, false, 0);
                this.scrolled_favorites.add_with_viewport (this.favorites);
                this.scrolled_own.add_with_viewport (this.own_list);

                this.notebook_own = new Widgets.Notebook ();
                this.notebook_own.append_page (this.scrolled_own, new Gtk.Label (_("Timeline")));
                this.notebook_own.append_page (this.scrolled_favorites, new Gtk.Label (_("Favorites")));
                this.notebook_own.append_page (this.scrolled_lists, new Gtk.Label (_("Lists")));
                this.own_box.pack_start (this.notebook_own, true, true, 0);

                this.user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                this.user_box_info = new Widgets.UserBox ();
                this.notebook_user = new Widgets.Notebook ();
                this.notebook_user.set_tabs (false);
                this.notebook_user.append_page (this.scrolled_user, new Gtk.Label (_("Timeline")));
                this.user_box.pack_start (this.user_box_info, false, false, 0);

                // separator
                this.user_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
                this.user_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);

                this.user_box.pack_start (this.notebook_user, true, true, 0);

                this.notebook.add_named (spinner_box, "loading");
                this.notebook.add_named (this.welcome, "welcome");
                this.notebook.add_named (this.scrolled_home, "home");
                this.notebook.add_named (this.scrolled_mentions, "mentions");
                this.notebook.add_named (this.scrolled_conversations_list, "dm");
                this.notebook.add_named (this.conversation_view, "conversation_view");
                this.notebook.add_named (this.own_box, "own");
                this.notebook.add_named (this.user_box, "user");
                this.notebook.add_named (this.scrolled_list, "list");
                this.notebook.add_named (this.scrolled_search, "search");
                this.notebook.add_named (this.error_page, "error");

                this.m_box.pack_start (this.notebook, true, true, 0);

                // Create the accounts switcher / revealer
                accounts_revealer = new Gtk.Revealer();
                accounts_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_LEFT);
                accounts_revealer.halign = Gtk.Align.END;

                accounts_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
                accounts_box.expand = false;
                accounts_box.get_style_context().add_class("account-box");
                accounts_box.halign = Gtk.Align.FILL;

                this.default_account = this.db.get_default_account ();
                this.default_account_id = this.db.get_account_id ();
                set_user_menu();

                accounts_revealer.add(accounts_box);
                this.m_box.pack_end(accounts_revealer, false, false, 0);

                avatar_button.clicked.connect(() => {
                    if(accounts_revealer.child_revealed) {
                        accounts_revealer.reveal_child = false;
                    } else {
                        accounts_revealer.visible = true;
                        accounts_revealer.reveal_child = true;
                    }
                });

                this.m_window.add(this.m_box);

                this.m_window.focus_in_event.connect ((w, e) => {
                    #if HAVE_LIBUNITY
                    if (get_total_unread () > 0)
                        this.launcher.clean_launcher_count ();
                    #endif
                    switch (this.current_timeline) {
                        case "home":
                            clean_tweets_indicator ();
                            break;
                        case "mentions":
                            clean_mentions_indicator ();
                            break;
                        case "dm":
                            clean_dm_indicator ();
                            break;
                    }

                    return true;
                });

                this.m_window.show_all ();
                accounts_revealer.visible = false;

                if (Option.START_HIDDEN) {
                    this.m_window.hide ();
                }

                if (this.default_account == null) {
                    this.switch_timeline ("welcome");
                } else {
                    this.api.token = this.default_account.token;
                    this.api.token_secret = this.default_account.token_secret;
                    this.init.begin ();
                }
            } else {
                this.m_window.show_all ();
                accounts_revealer.visible = false;
                #if HAVE_LIBUNITY
                if (get_total_unread () > 0)
                    this.launcher.clean_launcher_count ();
                #endif
                while (Gtk.events_pending ())
                    Gtk.main_iteration ();

                switch (this.current_timeline) {
                    case "home":
                        clean_tweets_indicator ();
                        break;
                    case "mentions":
                        clean_mentions_indicator ();
                        break;
                    case "dm":
                        clean_dm_indicator ();
                        break;
                }
                this.m_window.present ();
                check_timeout_health ();
            }
        }

        public void show_search_entry() {
            search_popover.show();
            search_visible = true;
            search_entry.visible = true;
            search_entry.grab_focus();
        }  

        protected override void open (File[] files, string hint) {
            foreach (File file in files) {
                string url = file.get_uri ();

                if ("birdie://user/" in url) {
                    user = url.replace ("birdie://user/", "");
                    if ("/" in user)
                        user = user.replace ("/", "");
                    if ("@" in user)
                        user = user.replace ("@", "");

                    this.show_user.begin ();
                } else if ("birdie://search/" in url) {
                    search_term = url.replace ("birdie://search/", "");
                    if ("/" in search_term)
                       search_term = search_term.replace ("/", "");
                    this.show_search.begin ();
                } else if ("birdie://list/" in url) {
                    list_id = url.replace ("birdie://list/", "");

                    list_owner = list_id.split("/")[0];
                    list_owner = list_owner.replace("@", "");
                    list_id = list_id.split("/")[1];

                    if ("/" in list_id)
                       list_id = search_term.replace ("/", "");

                    if (this.adding_to_list) {
                        if (list_owner == this.api.account.screen_name) {
                            this.api.add_to_list (list_id, user);
                            this.switch_timeline ("user");
                        } else {
                            Gtk.MessageDialog msg = new Gtk.MessageDialog (this.m_window, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK, _("You must select a list you own."));
			                msg.response.connect (() => {
			                    msg.destroy();
		                    });
		                    msg.show ();
                        }
                    } else {
                        this.show_list.begin ();
                    }
                }
            }
            activate ();
        }

        public async void request () throws ThreadError {
            SourceFunc callback = request.callback;

            ThreadFunc<void*> run = () => {

                this.new_api = new Twitter (this);

                Idle.add (() => {
                    var window_active = this.home.get_sensitive ();
                    this.set_widgets_sensitive (false);

                    var dialog = new Gtk.Dialog ();

                    var web_view = new WebKit.WebView ();
                    web_view.document_load_finished.connect (() => {
                        web_view.execute_script ("oldtitle=document.title;document.title=document.documentElement.innerHTML;");
                        var html = web_view.get_main_frame ().get_title ();
                        web_view.execute_script ("document.title=oldtitle;");

                        if ("<code>" in html) {
                            var pin = html.split ("<code>");
                            pin = pin[1].split ("</code>");
                            dialog.destroy ();

                            new Thread<void*> (null, () => {
                                this.switch_timeline ("loading");

                                int code = this.new_api.get_tokens (pin[0]);

                                if (code == 0) {

                                    this.api = this.new_api;
                                    this.init.begin ();
                                } else {
                                    this.switch_timeline ("welcome");
                                }

                                return null;
                            });
                        }
                    });

                    dialog.close.connect (() => {
                        this.set_widgets_sensitive (window_active);
                    });
                    web_view.load_uri (this.new_api.get_request ());
                    var scrolled_webview = new Gtk.ScrolledWindow (null, null);
                    scrolled_webview.add_with_viewport (web_view);
                    dialog.set_title (_("Sign in"));
                    dialog.get_content_area().pack_start (scrolled_webview, true, true, 0);
                    dialog.set_transient_for (this.m_window);
                    dialog.set_modal (true);
                    dialog.set_size_request (600, 600);
                    dialog.show_all ();

                    return false;
                });
                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);
            yield;
        }

        /*

        initializations methods

        */

        private void init_api () {
            this.api = null;
            this.api = new Twitter (this);
        }

        public async void init () throws ThreadError {
            SourceFunc callback = init.callback;

            Idle.add (() => {
                //this.appmenu.set_sensitive (false);
                return false;
            });

            this.switch_timeline ("loading");

            if (this.check_internet_connection ()) {

                ThreadFunc<void*> run = () => {

                    if (this.ready)
                        this.ready = false;

                    // initialize the api
                    this.api.auth ();
                    this.api.get_account ();

                    // get the current account
                    this.default_account = this.db.get_default_account ();
                    this.default_account_id = this.db.get_account_id ();

                    this.home_list.clear ();
                    this.mentions_list.clear ();
                    this.dm_list.clear ();
                    this.dm_sent_list.clear ();
                    this.own_list.clear ();
                    this.user_list.clear ();
                    this.favorites.clear ();
                    this.lists.clear ();

                    // get cached tweets, avatars and media

                    this.cache.set_default_account (this.default_account_id);
                    this.cache.load_cached_tweets ("tweets", this.home_list);
                    this.cache.load_cached_tweets ("mentions", this.mentions_list);
                    this.cache.load_cached_tweets ("dm_inbox", this.dm_list);
                    this.cache.load_cached_tweets ("dm_outbox", this.dm_sent_list);
                    this.cache.load_cached_tweets ("own", this.own_list);
                    this.cache.load_cached_tweets ("favorites", this.favorites);

                    // get fresh timelines

                    this.api.get_home_timeline ();
                    this.api.get_mentions_timeline ();
                    this.api.get_direct_messages ();
                    this.api.get_direct_messages_sent ();
                    this.api.get_own_timeline ();
                    this.api.get_favorites ();
                    this.api.get_lists ();

                    if (this.initialized) {
                        this.own_box_info.update (this.api.account);
                        this.user_box_info.update (this.api.account);
                        this.remove_timeouts ();
                    } else {
                        this.own_box_info.init (this.api.account, this);
                        this.user_box_info.init (this.api.account, this);
                    }

                    this.conversations_list.set_dm_lists(dm_list, dm_sent_list);

                    Media.get_userbox_avatar (this.own_box_info, true);
                    this.db.update_account (this.api.account);

                    this.set_account_avatar (this.api.account);

                    this.initialized = true;

                    this.home_list.show_all();
                    this.mentions_list.show_all();
                    this.dm_list.show_all();
                    this.dm_sent_list.show_all();
                    this.own_list.show_all();
                    this.favorites.show_all();

                    Idle.add((owned) callback);
                    return null;
                };

                Thread.create<void*>(run, false);

                // Wait for background thread to schedule our callback
                yield;
            } else {
                this.switch_timeline ("error");
            }
        }

        /*

        Setup user accounts menu

        */

        private void set_user_menu () {

            foreach(var w in accounts_box.get_children()) {
                accounts_box.remove(w);
            }

            // get all accounts
            List<User?> all_accounts = new List<User?> ();
            all_accounts = this.db.get_all_accounts ();

            foreach (var account in all_accounts) {

                try {
                    var pixbuf = new Gdk.Pixbuf.from_file (Environment.get_home_dir () +
                        "/.local/share/birdie/avatars/" + account.profile_image_file);

                    var avatar_switch_temp = new Granite.Widgets.Avatar();
                    avatar_switch_temp.pixbuf = pixbuf.scale_simple(50, 50, Gdk.InterpType.BILINEAR);

                    var avatar_switch_button = new Gtk.Button();
                    avatar_switch_button.image = avatar_switch_temp;
                    avatar_switch_button.relief = Gtk.ReliefStyle.NONE;
                    avatar_switch_button.set_tooltip_text(account.name + "\n@" + account.screen_name);

                    avatar_switch_button.clicked.connect (() => {

                        // If you click on the account that you're already on, view your profile
                        if(default_account.screen_name == account.screen_name) {
                            switch_timeline("own");
                        } else {
                            switch_account (account);
                        }

                        accounts_revealer.reveal_child = false;
                    });

                    avatar_switch_button.set_tooltip_text(_("Switch to the %s account".printf(account.name)));
                    
                    if(account.screen_name == this.default_account.screen_name) {
                        avatar_switch_button.set_tooltip_text(_("View your Twitter profile"));
                    }
                    
                    accounts_box.add(avatar_switch_button);
                } catch (Error e) {
                    stderr.printf("Error adding account to sidebar: %s\n", e.message);
                }
            }

            new_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.DIALOG);
            new_button.relief = Gtk.ReliefStyle.NONE;
            new_button.clicked.connect(() => { this.switch_timeline ("welcome"); });
            accounts_box.add(new_button);

        }

        private void set_account_avatar (User account) {

            Granite.Widgets.Avatar avatar = null;

            try {

                avatar = new Granite.Widgets.Avatar();
                var pixbuf = new Gdk.Pixbuf.from_file (Environment.get_home_dir () +
                    "/.local/share/birdie/avatars/" + account.profile_image_file);
                avatar.pixbuf = pixbuf.scale_simple(32, 32, Gdk.InterpType.BILINEAR);

                avatar.show ();

                avatar_button.image = avatar;
                avatar_button.visible = true;
            
            } catch (Error e) {
                // TODO: Show default menu icon if failed 
                debug ("Error loading avatar image: " + e.message);
            }
        }

        private void switch_account (User account) {
            this.set_account_avatar (account);

            this.search_list.clear ();
            this.search_entry.text = "";

            this.db.set_default_account (account);
            this.default_account = account;
            this.default_account_id = this.db.get_account_id ();

            this.set_widgets_sensitive (false);

            this.init_api ();
            switch_timeline ("loading");

            this.api.token = this.default_account.token;
            this.api.token_secret = this.default_account.token_secret;
            this.init.begin ();
        }

        public void set_widgets_sensitive (bool sensitive) {
            /*
            this.new_tweet.set_sensitive (sensitive);
            this.home.set_sensitive (sensitive);
            this.mentions.set_sensitive (sensitive);
            this.dm.set_sensitive (sensitive);
            this.profile.set_sensitive (sensitive);
            
            this.account_appmenu.set_sensitive (sensitive);
            this.remove_appmenu.set_sensitive (sensitive);
            */
            this.search.set_sensitive (sensitive);
        }

        public void switch_timeline (string new_timeline) {
            Idle.add( () => {
                this.changing_tab = true;

                bool active = false;

                if (this.adding_to_list) {
                    this.notebook_own.set_tabs (true);
                    this.notebook_own.page = 0;
                    this.adding_to_list = false;
                }

                if (this.current_timeline == new_timeline)
                    active = true;

                this.changing_tab = false;
                this.set_widgets_sensitive (true);

                switch (new_timeline) {
                    case "loading":
                        this.spinner.start ();
                        switcher.selected = -1;
                        break;
                    case "welcome":
                        switcher.selected = -1;
                        break;
                    case "home":
                        if (current_timeline == "home") this.scrolled_home.get_vadjustment().set_value(0);
                        this.clean_tweets_indicator ();
                        switcher.selected = 0;
                        break;
                    case "mentions":
                        if (current_timeline == "mentions") this.scrolled_mentions.get_vadjustment().set_value(0);
                        this.clean_mentions_indicator ();
                        switcher.selected = 1;
                        break;
                    case "dm":
                        if (current_timeline == "dm") this.scrolled_dm.get_vadjustment().set_value(0);
                        this.clean_dm_indicator ();
                        switcher.selected = 2;
                        break;
                    case "own":
                        if (current_timeline == "own") this.scrolled_own.get_vadjustment().set_value(0);
                        switcher.selected = -1;
                        break;
                    case "user":
                        this.scrolled_user.get_vadjustment().set_value(0);
                        switcher.selected = -1;
                        break;
                    case "list":
                        switcher.selected = -1;
                        break;
                    case "error":
                        this.set_widgets_sensitive (false);
                        switcher.selected = -1;
                        break;
                }

                this.notebook.set_visible_child_name (new_timeline);
                this.current_timeline = new_timeline;

                return false;
            });
        }

        private void on_conversation_selected(string name) {
            conversation_view.set_conversation(name, dm_list, dm_sent_list);
            this.notebook.set_visible_child (conversation_view);
        }

        /*

        GLib timeout methods

        */

        private void check_timeout_health () {
        	if (Utils.timeout_is_dead (this.update_interval, this.timer_date_offline)) {
        		debug ("Offline timeout died.");
        		GLib.Source.remove (this.timerID_offline);
        		add_timeout_offline ();
        	}

        	if (Utils.timeout_is_dead (this.update_interval, this.timer_date_online)) {
        		debug ("Online timeout died.");
        		GLib.Source.remove (this.timerID_online);
        		add_timeout_online ();
        	}
        }

        public void add_timeout_offline () {
        	this.timer_date_offline = new DateTime.now_utc ();

            this.timerID_offline = GLib.Timeout.add_seconds (60, () => {
                this.update_dates.begin ();
                return true;
            });
        }

        public void add_timeout_online () {
        	this.timer_date_online = new DateTime.now_utc ();

            this.timerID_online = GLib.Timeout.add_seconds (this.update_interval * 60, () => {
                new Thread<void*> (null, this.update_timelines);
                return true;
             });
        }

        private void remove_timeouts () {
            GLib.Source.remove (this.timerID_offline);
            GLib.Source.remove (this.timerID_online);
        }

        /*

        Update methods

        */

        public void* update_timelines () {
            if (this.check_internet_connection ()) {
                this.api.get_home_timeline ();
                this.api.get_mentions_timeline ();
                this.api.get_direct_messages ();

                this.home_list.show_all();
                this.mentions_list.show_all();
            } else {
                this.switch_timeline ("error");
            }
            return null;
        }

        public void update_home_ui () {
            string notify_header = "";
            string notify_text = "";
            string avatar = "";

            Idle.add (() => {
                this.home_tmp.foreach ((tweet) => {
                    this.home_list.remove (tweet);
                    this.home_tmp.remove (tweet);
                });

                this.api.home_timeline.foreach ((tweet) => {
                    this.home_list.append (tweet, this);
                    this.db.add_user.begin (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);

                    foreach (string hashtag in Utils.get_hashtags_list(tweet.text)) {
                        if (hashtag.has_prefix("#"))
                            this.db.add_hashtag.begin (hashtag.replace ("#", ""), this.default_account_id);
                    }

                    if (this.tweet_notification) {
                        if ((this.api.account.screen_name != tweet.user_screen_name) &&
                                this.api.home_timeline.length () <= this.limit_notifications) {
                            notify_header = _("New tweet from") + " " + tweet.user_screen_name;
                            notify_text = tweet.text;
                            avatar = tweet.profile_image_file;
                        }

                        if (this.api.account.screen_name != tweet.user_screen_name)
                            this.unread_tweets++;

                        if (this.tweet_notification && this.api.home_timeline.length () <=
                            this.limit_notifications  &&
                            this.api.home_timeline.length () > 0 &&
                            (this.api.account.screen_name != tweet.user_screen_name)) {
                                this.notification.notify (this,
                                                          notify_header,
                                                          notify_text,
                                                          "home",
                                                          false,
                                                          Environment.get_home_dir () + "/.cache/birdie/" + avatar);
                        }
                    }
                });

                if (this.tweet_notification && this.api.home_timeline.length () > this.limit_notifications && this.unread_tweets > 0) {
                    this.notification.notify (this, this.unread_tweets.to_string () + " " + _("new tweets"));
                }

                if (this.tweet_notification && get_total_unread () > 0) {
                    #if HAVE_LIBUNITY
                    this.launcher.set_count (get_total_unread ());
                    #endif
                }

                if (!this.ready) {
                    get_all_avatars.begin ();

                    this.ready = true;

                    this.add_timeout_online ();
                    this.add_timeout_offline ();

                    this.current_timeline = "home";
                    this.switch_timeline ("home");
                    this.set_widgets_sensitive (true);
                } else {
                    Media.get_avatar (this.home_list);
                }
                this.spinner.stop ();
                return false;
            });
        }

        public async void get_all_avatars () throws ThreadError {
            SourceFunc callback = get_all_avatars.callback;

            ThreadFunc<void*> run = () => {
                Media.get_avatar (this.home_list);
                Media.get_avatar (this.mentions_list);
                Media.get_avatar (this.dm_list);
                Media.get_avatar (this.dm_sent_list);
                Media.get_avatar (this.own_list);
                Media.get_avatar (this.favorites);
                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);
            yield;
        }

        public void update_dm_sent_ui () {
            Idle.add (() => {
                this.api.dm_sent_timeline.foreach ((tweet) => {
                    this.dm_sent_list.append(tweet, this);
                });

                if (this.ready)
                    Media.get_avatar (this.dm_sent_list);

                return false;
            });
        }

        public void update_own_timeline_ui () {
            Idle.add (() => {
                this.api.own_timeline.foreach ((tweet) => {
                    this.own_list.append (tweet, this);
                });

                if (this.ready)
                    Media.get_avatar (this.own_list);

                return false;
            });
        }

        public void update_favorites_ui () {
            Idle.add (() => {
                this.api.favorites.foreach ((tweet) => {
                    this.favorites.append(tweet, this);
                    this.db.add_user.begin (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                if (this.ready)
                    Media.get_avatar (this.favorites);

                return false;
            });
        }

        public void update_mentions_ui () {
            bool new_mentions = false;
            string notify_header = "";
            string notify_text = "";
            string avatar = "";

            Idle.add (() => {
                this.api.mentions_timeline.foreach ((tweet) => {
                    this.mentions_list.append (tweet, this);
                    this.db.add_user.begin (tweet.user_screen_name,
                            tweet.user_name, this.default_account_id);
                        if (this.mention_notification) {
                            if ((this.api.account.screen_name != tweet.user_screen_name) &&
                                    this.api.mentions_timeline.length () <= this.limit_notifications) {
                                notify_header = _("New mention from") + " " + tweet.user_screen_name;
                                notify_text = tweet.text;
                                avatar = tweet.profile_image_file;
                            }
                            if (this.api.account.screen_name != tweet.user_screen_name) {
                                this.unread_mentions++;
                                new_mentions = true;
                            }

                        if (this.tweet_notification && this.api.mentions_timeline.length () <=
                            this.limit_notifications &&
                            this.api.mentions_timeline.length () > 0 &&
                            (this.api.account.screen_name != tweet.user_screen_name)) {
                                this.notification.notify (this, notify_header, notify_text, "mentions", false, Environment.get_home_dir () + "/.cache/birdie/" + avatar);
                        }
                    }
                });

                if (this.mention_notification && this.api.mentions_timeline.length () > this.limit_notifications) {
                    this.notification.notify (this, this.unread_mentions.to_string () + " " + _("new mentions"), "", "mentions");
                }

                if (this.mention_notification && new_mentions) {
                    #if HAVE_LIBUNITY
                    this.launcher.set_count (get_total_unread ());
                    #endif
                }

                if (this.ready)
                    Media.get_avatar (this.mentions_list);

                return false;
            });
        }

        public void update_dm_ui () {
            bool new_dms = false;
            string notify_header = "";
            string notify_text = "";
            string avatar = "";

            Idle.add (() => {
                this.api.dm_timeline.foreach ((tweet) => {
                    info("New DM: %s".printf(tweet.text));
                    this.conversations_list.set_dm_lists(dm_list, dm_sent_list);
                    this.dm_list.append (tweet, this);
                    this.db.add_user.begin (tweet.user_screen_name,
                            tweet.user_name, this.default_account_id);
                    if (this.dm_notification) {
                        if ((this.api.account.screen_name !=
                                    tweet.user_screen_name) &&
                                    this.api.dm_timeline.length () <=
                                    this.limit_notifications) {
                            notify_header = _("New direct message from") + " " + tweet.user_screen_name;
                            notify_text = tweet.text;
                            avatar = tweet.profile_image_file;
                        }
                        if (this.api.account.screen_name != tweet.user_screen_name) {
                            this.unread_dm++;
                            new_dms = true;
                        }

                        if (this.tweet_notification && this.api.dm_timeline.length () <=
                            this.limit_notifications  &&
                            this.api.dm_timeline.length () > 0 &&
                            (this.api.account.screen_name != tweet.user_screen_name)) {
                                this.notification.notify (this, notify_header, notify_text, "dm", true, Environment.get_home_dir () + "/.cache/birdie/" + avatar);
                        }
                    }
                });


                if (this.ready)
                    Media.get_avatar (this.dm_list);

                if (this.dm_notification && this.api.dm_timeline.length () > this.limit_notifications) {
                    this.notification.notify (this, this.unread_dm.to_string () + " " + _("new direct messages"), "", "dm", true);
                }

                if (this.dm_notification && new_dms) {
                    #if HAVE_LIBUNITY
                    this.launcher.set_count (get_total_unread ());
                    #endif
                }

                return false;
            });
        }

        public async void update_dates () throws ThreadError {
            SourceFunc callback = update_dates.callback;

            ThreadFunc<void*> run = () => {
                this.home_list.update_date ();
                this.mentions_list.update_date ();
                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);
            yield;
        }

        private int get_total_unread () {
            return this.unread_tweets + this.unread_mentions + this.unread_dm;
        }

        /*

        Older statuses

        */

        private void get_older_tweets ()  {
            if (this.check_internet_connection ()) {
                this.api.get_older_home_timeline ();
            } else {
                this.switch_timeline ("error");
            }
        }

        public void update_older_home_ui () {
            Idle.add (() => {
                this.home_tmp.foreach ((tweet) => {
                    this.home_list.remove (tweet);
                    this.home_tmp.remove (tweet);
                });

                this.api.home_timeline.foreach ((tweet) => {
                    this.home_list.prepend (tweet, this);
                    this.db.add_user.begin (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                if (!this.ready) {
                    get_all_avatars.begin ();
                    this.ready = true;
                    this.set_widgets_sensitive (true);
                } else {
                    Media.get_avatar (this.home_list);
                }
                return false;
            });
        }

        private void get_older_mentions ()  {
            if (this.check_internet_connection ()) {
                this.api.get_older_mentions_timeline ();
            } else {
                this.switch_timeline ("error");
            }
        }

        public void update_older_mentions_ui () {
            Idle.add (() => {
                this.home_tmp.foreach ((tweet) => {
                    this.mentions_list.remove (tweet);
                });

                this.api.mentions_timeline.foreach ((tweet) => {
                    this.mentions_list.prepend (tweet, this);
                    this.db.add_user.begin (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                if (!this.ready) {
                    get_all_avatars.begin ();
                    this.ready = true;
                    this.set_widgets_sensitive (true);
                } else {
                    Media.get_avatar (this.mentions_list);
                }
                return false;
            });
        }

        private void get_older_search ()  {
            if (this.check_internet_connection ()) {
                this.api.get_older_search_timeline (search_term);
            } else {
                this.switch_timeline ("error");
            }
        }

        public void update_older_search_ui () {
            Idle.add (() => {
                search_entry.text = search_term;

                this.api.search_timeline.foreach ((tweet) => {
                    this.search_list.prepend (tweet, this);
                });

                if (this.ready)
                    Media.get_avatar (this.search_list);

                return false;
            });
        }

        /*

        Indicator cleaning

        */

        private void clean_tweets_indicator () {
            this.unread_tweets = 0;
            #if HAVE_LIBUNITY
            this.launcher.set_count (get_total_unread ());
            #endif
        }

        private void clean_mentions_indicator () {
            this.unread_mentions = 0;
            #if HAVE_LIBUNITY
            this.launcher.set_count (get_total_unread ());
            #endif
        }

        private void clean_dm_indicator () {
            this.unread_dm = 0;
            #if HAVE_LIBUNITY
            this.launcher.set_count (get_total_unread ());
            #endif
        }

        /*

        Callback method for sending messages

        */

        public void tweet_callback (string text, string id,
            string user_screen_name, bool dm, string media_uri) {

            int64 code;
            var text_url = "";
            var media_out = "";

            if (this.check_internet_connection ()) {
                if (dm)
                    if (media_uri == "")
                        code = this.api.send_direct_message (user_screen_name, text);
                    else
                        code = this.api.send_direct_message_with_media (user_screen_name, text, media_uri, out media_out);
                else
                    if (media_uri == "")
                        code = this.api.update (text, id);
                    else
                        code = this.api.update_with_media (text, id, media_uri, out media_out);

                if (code != 1) {
                    text_url = Utils.highlight_all (text);

                    if (media_out != "") {
                        text_url = text_url + " <a href='" + media_out + "'>" + media_out + "</a>";
                    }

                    string user = user_screen_name;

                    if ("@" in user_screen_name)
                        user = user.replace ("@", "");

                    if (user == "" || !dm)
                        user = this.api.account.screen_name;

                    Tweet tweet_tmp = new Tweet (code.to_string (), code.to_string (),
                        this.api.account.name, user, text_url, "", this.api.account.profile_image_url,
                        this.api.account.profile_image_file, false, false, dm);

                    if (dm) {
                        this.dm_sent_list.append (tweet_tmp, this);
                        this.switch_timeline ("dm");
                        Idle.add (() => {
                            this.notebook_dm.page = 1;
                            Media.get_avatar (this.dm_sent_list);
                            //Media.get_imgur_media (media_uri, null, this.dm_sent_list, tweet_tmp);
                            return false;
                        });
                    } else {
                        Idle.add (() => {
                            this.home_tmp.append (tweet_tmp);
                            this.home_list.append (tweet_tmp, this);
                            this.own_list.append (tweet_tmp, this);

                            Media.get_avatar (this.home_list);
                            Media.get_avatar (this.own_list);
                            Media.get_imgur_media (media_uri, null, this.home_list, tweet_tmp);
                            Media.get_imgur_media (media_uri, null, this.own_list, tweet_tmp);
                            return false;
                        });

                        this.switch_timeline ("home");
                    }
                }
            } else {
                this.switch_timeline ("error");
            }
        }

        public async void show_user () throws ThreadError {
            SourceFunc callback = show_user.callback;

            ThreadFunc<void*> run = () => {
                if (this.check_internet_connection ()) {
                    Idle.add (() => {
                        this.switch_timeline ("loading");
                        return false;
                    });

                    this.user_list.clear ();
                    this.api.get_user_timeline (user);
                } else {
                    this.switch_timeline ("error");
                }
                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);
            yield;
        }

        public void update_user_timeline_ui () {
            Idle.add (() => {
                if (this.api.user_timeline.length () == 0) {
                    this.switch_timeline ("search");
                    return false;
                }

                this.user_box_info.update (this.api.user);
                Media.get_userbox_avatar (this.user_box_info);

                this.switch_timeline ("user");


                this.api.user_timeline.foreach ((tweet) => {
                    this.user_list.append (tweet, this);
                });

                if (this.ready) {
                    Media.get_avatar (this.user_list);
                    Idle.add (() => {
                        this.spinner.stop ();
                        return false;
                    });
                }

                return false;
            });
        }

        public void update_search_ui () {
            Idle.add (() => {
                this.switch_timeline ("search");

                search_entry.text = search_term;

                this.api.search_timeline.foreach ((tweet) => {
                    this.search_list.append (tweet, this);
                });

                if (this.ready) {
                    Media.get_avatar (this.search_list);
                    Idle.add (() => {
                        this.spinner.stop ();
                        this.scrolled_search.get_vadjustment().set_value(0);
                        return false;
                    });
                }

                return false;
            });
        }

        private async void show_search () throws ThreadError {

            search_popover.hide();
            
            SourceFunc callback = show_search.callback;

            ThreadFunc<void*> run = () => {
                if (search_term != "" && search_term[0] == '@' && !(" " in search_term) && !("%20" in search_term)) {
                    user = search_term.replace ("@", "");
                    this.show_user.begin ();
                    return null;
                }

                if (this.check_internet_connection ()) {
                    this.search_list.clear ();

                    Idle.add (() => {
                        this.switch_timeline ("loading");
                        search_entry.text = search_term;
                        return false;
                    });

                    this.api.get_search_timeline (search_term);
                } else {
                    this.switch_timeline ("error");
                }
                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);
            yield;
        }

        public void update_list_ui () {
            Idle.add (() => {
                this.switch_timeline ("list");

                this.api.list_timeline.foreach ((tweet) => {
                    this.list_list.append (tweet, this);
                });

                if (this.ready)
                    Media.get_avatar (this.list_list);

                this.spinner.stop ();

                return false;
            });
        }

        private async void show_list () throws ThreadError {
            SourceFunc callback = show_list.callback;

            ThreadFunc<void*> run = () => {
                if (this.check_internet_connection ()) {
                    this.list_list.clear ();
                    this.list_list.list_id = list_id;
                    this.list_list.list_owner = list_owner;

                    Idle.add (() => {
                        this.switch_timeline ("loading");
                        return false;
                    });

                    this.api.get_list_timeline (list_id);
                } else {
                    this.switch_timeline ("error");
                }
                Idle.add((owned) callback);
                return null;
            };
            Thread.create<void*>(run, false);
            yield;
        }

        private bool check_internet_connection() {
            if (!Utils.check_internet_connection ()) {
                return false;
            }
            return true;
        }

        private void on_exit() {
            // save window size and position
            int x, y, w, h;
            m_window.get_position (out x, out y);
            m_window.get_size (out w, out h);
            this.settings.set_int ("opening-x", x);
            this.settings.set_int ("opening-y", y);
            this.settings.set_int ("window-width", w);
            this.settings.set_int ("window-height", h);

            // destroy notifications
            this.notification.uninit ();
        }
    }
}
