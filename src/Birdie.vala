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

namespace Birdie {
#if HAVE_GRANITE
    public class Birdie : Granite.Application {
#else
    public class Birdie : Gtk.Application {
#endif
        public Widgets.UnifiedWindow m_window;
        public Widgets.TweetList home_list;
        public Widgets.TweetList mentions_list;
        public Widgets.TweetList dm_list;
        public Widgets.TweetList dm_sent_list;
        public Widgets.TweetList own_list;
        public Widgets.TweetList favorites;
        public Widgets.TweetList user_list;
        public Widgets.TweetList search_list;

        private Gtk.MenuItem account_appmenu;
        private Gtk.MenuItem remove_appmenu;
        private Widgets.MenuPopOver menu;
        private List<Gtk.Widget> menu_tmp;

        private Gtk.ToolButton new_tweet;
        public Gtk.ToggleToolButton home;
        public Gtk.ToggleToolButton mentions;
        public Gtk.ToggleToolButton dm;
        public Gtk.ToggleToolButton profile;
        private Gtk.ToggleToolButton search;

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
        private Gtk.ScrolledWindow scrolled_search;

        private Widgets.Welcome welcome;
        private Widgets.ErrorPage error_page;

        private Widgets.Notebook notebook;
        private Widgets.Notebook notebook_dm;
        private Widgets.Notebook notebook_own;
        private Widgets.Notebook notebook_user;

        private Gtk.Spinner spinner;

        private GLib.List<Tweet> home_tmp;

        public API api;
        public API new_api;

        public string current_timeline;

        #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
        private Utils.Indicator indicator;
        #endif

        #if HAVE_LIBUNITY
        private Utils.Launcher launcher;
        #endif

        private int unread_tweets;
        private int unread_mentions;
        private int unread_dm;

        private bool tweet_notification;
        private bool mention_notification;
        private bool dm_notification;
        private bool legacy_window;
        private int update_interval;

        public Settings settings;

        public string user;
        private string search_term;

        public bool initialized;
        private bool changing_tab;

        public SqliteDatabase db;

        private User default_account;
        public int? default_account_id;

        private uint timerID_online;
        private uint timerID_offline;

        private int limit_notifications;

        public static const OptionEntry[] app_options = {
            { "debug", 'd', 0, OptionArg.NONE, out Option.DEBUG, "Enable debug logging", null },
            { "start-hidden", 's', 0, OptionArg.NONE, out Option.START_HIDDEN, "Start hidden", null },
            { null }
        };

#if HAVE_GRANITE
        private Granite.Widgets.ToolButtonWithMenu appmenu;
        private Granite.Widgets.SearchBar search_entry;

        construct {
            program_name        = "Birdie";
            exec_name           = "birdie";
            build_version       = Constants.VERSION;
            app_years           = "2013";
            app_icon            = "birdie";
            app_launcher        = "birdie.desktop";
            application_id      = "org.pantheon.birdie";
            main_url            = "http://www.ivonunes.net/birdie/";
            bug_url             = "http://bugs.launchpad.net/birdie";
            help_url            = "http://answers.launchpad.net/birdie";
            translate_url       = "http://translations.launchpad.net/birdie";
            about_authors       = {"Ivo Nunes <ivo@elementaryos.org>", "Vasco Nunes <vascomfnunes@gmail.com>"};
            about_artists       = {"Daniel Foré <daniel@elementaryos.org>", "Mustapha Asbbar"};
            about_comments      = null;
            about_documenters   = {};
            about_translators   = null;
            about_license_type  = Gtk.License.GPL_3_0;
        }
#else
        private Gtk.Entry search_entry;
        private Gtk.MenuToolButton appmenu;
#endif

        public Birdie () {
            GLib.Object(application_id: "org.birdie", flags: ApplicationFlags.HANDLES_OPEN);

            Intl.bindtextdomain ("birdie", Constants.DATADIR + "/locale");

            this.initialized = false;
            this.changing_tab = false;

            // create cache and db dirs if needed
            Utils.create_dir_with_parents ("/.cache/birdie/media");
            Utils.create_dir_with_parents ("/.local/share/birdie/avatars");

            // init database object
            this.db = new SqliteDatabase ();
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
                this.settings = new Settings ("org.pantheon.birdie");
                this.tweet_notification = settings.get_boolean ("tweet-notification");
                this.mention_notification = settings.get_boolean ("mention-notification");
                this.dm_notification = settings.get_boolean ("dm-notification");
                //this.legacy_window = settings.get_boolean ("legacy-window");
                this.legacy_window = true;
                this.update_interval = settings.get_int ("update-interval");
                this.limit_notifications = settings.get_int ("limit-notifications");

                if (this.legacy_window)
                    this.m_window = new Widgets.UnifiedWindow ("Birdie", true);
                else
                    this.m_window = new Widgets.UnifiedWindow ();

                this.m_window.set_default_size (355, 500);
                this.m_window.set_size_request (355, 50);
                this.m_window.set_application (this);

                // restore main window size and position
                this.m_window.opening_x = settings.get_int ("opening-x");
                this.m_window.opening_y = settings.get_int ("opening-y");
                this.m_window.window_width = settings.get_int ("window-width");
                this.m_window.window_height = settings.get_int ("window-height");
                this.m_window.restore_window ();

                #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
                this.indicator = new Utils.Indicator (this);
                #endif

                #if HAVE_LIBUNITY
                this.launcher = new Utils.Launcher (this);
                #endif

                this.unread_tweets = 0;
                this.unread_mentions = 0;
                this.unread_dm = 0;

                if (this.tweet_notification || this.mention_notification || this.dm_notification)
                    this.m_window.hide_on_delete ();

                this.new_tweet = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("mail-message-new", Gtk.IconSize.LARGE_TOOLBAR), _("New Tweet"));
                new_tweet.set_tooltip_text (_("New Tweet"));

                new_tweet.clicked.connect (() => {
                    bool is_dm = false;

                    if (this.current_timeline == "dm")
                        is_dm = true;

                    Widgets.TweetDialog dialog = new Widgets.TweetDialog (this, "", "", is_dm);
                    dialog.show_all ();
                });

                new_tweet.set_sensitive (false);
                this.m_window.add_bar (new_tweet);

                var left_sep = new Gtk.SeparatorToolItem ();
                left_sep.draw = false;
                left_sep.set_expand (true);
                this.m_window.add_bar (left_sep);
                this.home = new Gtk.ToggleToolButton ();
                this.home.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-home", Gtk.IconSize.LARGE_TOOLBAR));

                home.set_tooltip_text (_("Home"));
                home.set_label (_("Home"));

                home.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("home");
                });
                this.home.set_sensitive (false);
                this.m_window.add_bar (home);

                this.mentions = new Gtk.ToggleToolButton ();
                this.mentions.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-mentions", Gtk.IconSize.LARGE_TOOLBAR));
                mentions.set_tooltip_text (_("Mentions"));
                mentions.set_label (_("Mentions"));

                mentions.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("mentions");
                });

                this.mentions.set_sensitive (false);
                this.m_window.add_bar (mentions);

                this.dm = new Gtk.ToggleToolButton ();
                this.dm.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-dm", Gtk.IconSize.LARGE_TOOLBAR));
                dm.set_tooltip_text (_("Direct Messages"));
                dm.set_label (_("Direct Messages"));
                dm.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("dm");
                });
                this.dm.set_sensitive (false);
                this.m_window.add_bar (dm);

                this.profile = new Gtk.ToggleToolButton ();
                this.profile.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-profile", Gtk.IconSize.LARGE_TOOLBAR));
                profile.set_tooltip_text (_("Profile"));
                profile.set_label (_("Profile"));

                profile.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("own");
                });
                this.profile.set_sensitive (false);
                this.m_window.add_bar (profile);

                this.search = new Gtk.ToggleToolButton ();
                this.search.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-search", Gtk.IconSize.LARGE_TOOLBAR));
                search.set_tooltip_text (_("Search"));
                search.set_label (_("Search"));

                search.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("search");
                });
                this.search.set_sensitive (false);
                this.m_window.add_bar (search);

                var right_sep = new Gtk.SeparatorToolItem ();
                right_sep.draw = false;
                right_sep.set_expand (true);
                this.m_window.add_bar (right_sep);

                menu = new Widgets.MenuPopOver ();
                this.account_appmenu = new Gtk.MenuItem.with_label (_("Add Account"));
                account_appmenu.activate.connect (() => {
                    this.switch_timeline ("welcome");
                });
                this.account_appmenu.set_sensitive (false);

                this.remove_appmenu = new Gtk.MenuItem.with_label (_("Remove Account"));
                remove_appmenu.activate.connect (() => {
                    // confirm remove account
                    Widgets.AlertDialog confirm = new Widgets.AlertDialog (this.m_window,
                        Gtk.MessageType.QUESTION, _("Remove this account?"),
                        _("Remove"), _("Cancel"));
                    Gtk.ResponseType response = confirm.run ();
                    if (response == Gtk.ResponseType.OK) {
                        var appmenu_icon = new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU);
                        appmenu_icon.show ();
                        this.appmenu.set_icon_widget (appmenu_icon);
                        this.set_widgets_sensitive (false);
                        this.db.remove_account (this.default_account);
                        User account = this.db.get_default_account ();
                        this.set_user_menu ();

                        if (account == null) {
                            this.init_api ();
                            this.switch_timeline ("welcome");
                        } else {
                            this.switch_account (account);
                        }
                    }
                });
                this.remove_appmenu.set_sensitive (false);

                var about_appmenu = new Gtk.MenuItem.with_label (_("About"));
                about_appmenu.activate.connect (() => {
#if HAVE_GRANITE
                    show_about (this.m_window);
#else
                    Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
                    dialog.set_destroy_with_parent (true);
                    dialog.set_transient_for (this.m_window);
                    dialog.set_modal (true);

                    dialog.artists = {"Daniel Foré", "Mustapha Asbbar"};
                    dialog.authors = {"Ivo Nunes", "Vasco Nunes"};
                    dialog.documenters = null;
                    dialog.translator_credits = null;

                    dialog.logo_icon_name = "birdie";
                    dialog.program_name = "Birdie";
                    dialog.comments = Constants.COMMENT;
                    dialog.copyright = "Copyright © 2013 Ivo Nunes / Vasco Nunes";
                    dialog.version = Constants.VERSION;

                    dialog.license_type = Gtk.License.GPL_3_0;
                    dialog.wrap_license = true;

                    dialog.website = "http://www.ivonunes.net/birdie";
                    dialog.website_label = "Birdie Website";

                    dialog.response.connect ((response_id) => {
                        if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
                            dialog.destroy ();
                        }
                    });

                    dialog.present ();
#endif
                });
                var donate_appmenu = new Gtk.MenuItem.with_label (_("Donate"));
                donate_appmenu.activate.connect (() => {
                    try {
                        GLib.Process.spawn_command_line_async ("x-www-browser http://www.ivonunes.net/birdie/donate.html");
                    } catch (Error e) {

                    }
                });
                var quit_appmenu = new Gtk.MenuItem.with_label (_("Quit"));
                quit_appmenu.activate.connect (() => {
                    // save window size and position
                    int x, y, w, h;
                    m_window.get_position (out x, out y);
                    m_window.get_size (out w, out h);
                    this.settings.set_int ("opening-x", x);
                    this.settings.set_int ("opening-y", y);
                    this.settings.set_int ("window-width", w);
                    this.settings.set_int ("window-height", h);

                    m_window.destroy ();
                });
                menu.add (account_appmenu);
                menu.add (remove_appmenu);
                menu.add (new Gtk.SeparatorMenuItem ());
                menu.add (about_appmenu);
                menu.add (donate_appmenu);
                menu.add (quit_appmenu);

                #if HAVE_GRANITE
                this.appmenu = new Granite.Widgets.ToolButtonWithMenu (new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU), _("Menu"), menu);
                menu.move_to_widget (appmenu);
                #else
                this.appmenu = new Gtk.MenuToolButton (new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU), _("Menu"));
                this.appmenu.set_menu (menu);
                #endif

                this.m_window.add_bar (appmenu);

                this.home_list = new Widgets.TweetList ();
                this.mentions_list = new Widgets.TweetList ();
                this.dm_list = new Widgets.TweetList ();
                this.dm_sent_list = new Widgets.TweetList ();
                this.own_list = new Widgets.TweetList ();
                this.user_list = new Widgets.TweetList ();
                this.favorites = new Widgets.TweetList ();
                this.search_list = new Widgets.TweetList ();

                this.scrolled_home = new Gtk.ScrolledWindow (null, null);
                this.scrolled_home.add_with_viewport (home_list);

                this.scrolled_mentions = new Gtk.ScrolledWindow (null, null);
                this.scrolled_mentions.add_with_viewport (mentions_list);

                this.scrolled_dm = new Gtk.ScrolledWindow (null, null);
                this.scrolled_dm.add_with_viewport (dm_list);
                this.scrolled_dm_sent = new Gtk.ScrolledWindow (null, null);
                this.scrolled_dm_sent.add_with_viewport (dm_sent_list);

                this.scrolled_own = new Gtk.ScrolledWindow (null, null);

                this.scrolled_favorites = new Gtk.ScrolledWindow (null, null);

                this.scrolled_user = new Gtk.ScrolledWindow (null, null);
                this.scrolled_user.add_with_viewport (user_list);

                this.scrolled_search = new Gtk.ScrolledWindow (null, null);
                this.scrolled_search.add_with_viewport (search_list);

                this.welcome = new Widgets.Welcome (this);
                this.error_page = new Widgets.ErrorPage (this);

                this.notebook_dm = new Widgets.Notebook ();
                this.notebook_dm.append_page (this.scrolled_dm, new Gtk.Label (_("Received")));
                this.notebook_dm.append_page (this.scrolled_dm_sent, new Gtk.Label (_("Sent")));

                this.notebook = new Widgets.Notebook ();
                this.notebook.set_tabs (false);
                this.notebook.set_border (false);

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

                var search_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);

#if HAVE_GRANITE
                search_entry = new Granite.Widgets.SearchBar (_("Search"));
#else
                search_entry = new Gtk.Entry ();
#endif

                search_entry.activate.connect (() => {
                    this.search_term = ((Gtk.Entry)search_entry).get_text ();
                    new Thread<void*> (null, this.show_search);
                });
                search_box.pack_start (search_entry, false, false, 0);
                search_box.pack_start (this.scrolled_search, true, true, 0);

                this.notebook.append_page (spinner_box, new Gtk.Label (_("Loading")));
                this.notebook.append_page (this.welcome, new Gtk.Label (_("Welcome")));
                this.notebook.append_page (this.scrolled_home, new Gtk.Label (_("Home")));
                this.notebook.append_page (this.scrolled_mentions, new Gtk.Label (_("Mentions")));
                this.notebook.append_page (this.notebook_dm, new Gtk.Label (_("Direct Messages")));
                this.notebook.append_page (this.own_box, new Gtk.Label (_("Profile")));
                this.notebook.append_page (this.user_box, new Gtk.Label (_("User")));
                this.notebook.append_page (search_box, new Gtk.Label (_("Search")));
                this.notebook.append_page (this.error_page, new Gtk.Label (_("Error")));

                this.m_window.add (this.notebook);

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

                if (Option.START_HIDDEN) {
                    this.m_window.hide ();
                }

                this.default_account = this.db.get_default_account ();
                this.default_account_id = this.db.get_account_id ();

                if (this.default_account == null) {
                    this.switch_timeline ("welcome");
                } else {
                    this.api.token = this.default_account.token;
                    this.api.token_secret = this.default_account.token_secret;
                    new Thread<void*> (null, this.init);
                }
            } else {
                this.m_window.show_all ();
                this.m_window.present ();
                #if HAVE_LIBUNITY
                if (get_total_unread () > 0)
                    this.launcher.clean_launcher_count ();
                #endif
                while (Gtk.events_pending ())
                    Gtk.main_iteration ();

                var xid = Gdk.X11Window.get_xid (this.m_window.get_window ());
                var w = Wnck.Window.get (xid);
                Wnck.Screen.get_default().force_update ();
                if (w != null) {
                    w.activate (Gdk.x11_get_server_time (this.m_window.get_window ()));
                }
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
            }
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

                    new Thread<void*> (null, show_user);
                } else if ("birdie://search/" in url) {
                    search_term = url.replace ("birdie://search/", "");
                    if ("/" in search_term)
                       search_term = search_term.replace ("/", "");
                    new Thread<void*> (null, show_search);
                }
            }
            activate ();
        }

        public void new_tweet_keybinding () {
            Widgets.TweetDialog dialog = new Widgets.TweetDialog (this, "", "", false);
            dialog.show_all ();
        }

        public void* request () {
            this.new_api = new Twitter (this.db);

            Idle.add (() => {
                var window_active = this.home.get_sensitive ();
                this.set_widgets_sensitive (false);

                var light_window = new Widgets.LightWindow (false);
                var web_view = new WebKit.WebView ();
                web_view.document_load_finished.connect (() => {
                    web_view.execute_script ("oldtitle=document.title;document.title=document.documentElement.innerHTML;");
                    var html = web_view.get_main_frame ().get_title ();
                    web_view.execute_script ("document.title=oldtitle;");

                    if ("<code>" in html) {
                        var pin = html.split ("<code>");
                        pin = pin[1].split ("</code>");
                        light_window.destroy ();

                        new Thread<void*> (null, () => {
                            this.switch_timeline ("loading");

                            int code = this.new_api.get_tokens (pin[0]);

                            if (code == 0) {
                                Idle.add (() => {
                                    var appmenu_icon = new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU);
                                    appmenu_icon.show ();
                                    this.appmenu.set_icon_widget (appmenu_icon);
                                    this.set_widgets_sensitive (false);
                                    return false;
                                });

                                this.api = this.new_api;
                                new Thread<void*> (null, this.init);
                            } else {
                                this.switch_timeline ("welcome");
                            }

                            return null;
                        });
                    }
                });
                light_window.destroy.connect (() => {
                    this.set_widgets_sensitive (window_active);
                });
                web_view.load_uri (this.new_api.get_request ());
                var scrolled_webview = new Gtk.ScrolledWindow (null, null);
                scrolled_webview.add_with_viewport (web_view);
                light_window.set_title (_("Sign in"));
                light_window.add (scrolled_webview);
                light_window.set_transient_for (this.m_window);
                light_window.set_modal (true);
                light_window.set_size_request (600, 600);
                light_window.show_all ();

                return false;
            });

            return null;
        }

        /*

        initializations methods

        */

        private void init_api () {
            this.api = new Twitter (this.db);
        }

        public void* init () {
            this.switch_timeline ("loading");

            if (this.check_internet_connection ()) {
                this.api.auth ();
                this.api.get_account ();

                this.api.get_home_timeline ();
                this.api.get_mentions_timeline ();
                this.api.get_direct_messages ();
                this.api.get_direct_messages_sent ();
                this.api.get_own_timeline ();
                this.api.get_favorites ();

                this.home_list.clear ();
                this.mentions_list.clear ();
                this.dm_list.clear ();
                this.dm_sent_list.clear ();
                this.own_list.clear ();
                this.favorites.clear ();

                this.default_account = this.db.get_default_account ();
                this.default_account_id = this.db.get_account_id ();

                this.api.home_timeline.foreach ((tweet) => {
                    this.home_list.append (tweet, this);
                    this.db.add_user (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                this.api.mentions_timeline.foreach ((tweet) => {
                    this.mentions_list.append(tweet, this);
                    this.db.add_user (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                this.api.dm_timeline.foreach ((tweet) => {
                    this.dm_list.append(tweet, this);
                    this.db.add_user (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                this.api.dm_sent_timeline.foreach ((tweet) => {
                    this.dm_sent_list.append(tweet, this);
                });

                this.api.own_timeline.foreach ((tweet) => {
                    this.own_list.append(tweet, this);
                });

                this.api.favorites.foreach ((tweet) => {
                    this.favorites.append(tweet, this);
                    this.db.add_user (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                });

                Idle.add (() => {
                    if (this.initialized) {
                        this.own_box_info.update (this.api.account);
                        this.user_box_info.update (this.api.account);
                        this.remove_timeouts ();
                    } else {
                        this.own_box_info.init (this.api.account, this);
                        this.user_box_info.init (this.api.account, this);
                    }

                    get_userbox_avatar (this.own_box_info, true);
                    // update account db
                    this.db.update_account (this.api.account);
                    this.set_user_menu ();
                    this.initialized = true;

                    return false;
                });

                this.add_timeout_online ();
                this.add_timeout_offline ();

                this.current_timeline = "home";
                this.switch_timeline ("home");

                this.spinner.stop ();

                this.new_tweet.set_sensitive (true);
                this.home.set_sensitive (true);
                this.mentions.set_sensitive (true);
                this.dm.set_sensitive (true);
                this.profile.set_sensitive (true);
                this.search.set_sensitive (true);
                this.account_appmenu.set_sensitive (true);
                this.remove_appmenu.set_sensitive (true);

                get_avatar (this.home_list);
                get_avatar (this.mentions_list);
                get_avatar (this.dm_list);
                get_avatar (this.dm_sent_list);
                get_avatar (this.own_list);
                get_avatar (this.favorites);
            } else {
                this.switch_timeline ("error");
            }

            return null;
        }

        /*

        Setup user accounts menu

        */

        private void set_user_menu () {
            this.menu_tmp.foreach ((w) => {
                this.menu.remove (w);
                this.menu_tmp.remove (w);
            });

            // get all accounts
            List<User?> all_accounts = new List<User?> ();
            all_accounts = this.db.get_all_accounts ();

            if (all_accounts.length () > 0) {
                var sep = new Gtk.SeparatorMenuItem ();
                this.menu_tmp.prepend (sep);
                this.menu.prepend (sep);
            }

            foreach (var account in all_accounts) {
                Gdk.Pixbuf avatar_pixbuf = null;

                try {
                    avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (Environment.get_home_dir () +
                        "/.local/share/birdie/avatars/" + account.profile_image_file, 24, 24, true);
                } catch (Error e) {
                    debug ("Error creating pixbuf: " + e.message);
                }

                Gtk.Image avatar_image = new Gtk.Image.from_pixbuf (avatar_pixbuf);
                avatar_image.show ();
                this.appmenu.set_icon_widget (avatar_image);

                Gtk.Image avatar_image_menu = new Gtk.Image.from_file (Environment.get_home_dir () +
                    "/.local/share/birdie/avatars/" + account.profile_image_file);
                Gtk.ImageMenuItem account_menu_item = new Gtk.ImageMenuItem.with_label (account.name +
                    "\n@" + account.screen_name);

                account_menu_item.activate.connect (() => {
                    switch_account (account);
                });

                foreach (var child in account_menu_item.get_children ()) {
                    if (child is Gtk.Label)
                        ((Gtk.Label)child).set_markup ("<b>" + account.name +
                            "</b>\n@" + account.screen_name);
                }
                account_menu_item.set_image (avatar_image_menu);
                account_menu_item.set_always_show_image (true);

                this.menu_tmp.prepend (account_menu_item);
                this.menu.prepend (account_menu_item);
            }

            this.menu.show_all ();
        }

        private void switch_account (User account) {
            var appmenu_icon = new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU);
            appmenu_icon.show ();
            this.appmenu.set_icon_widget (appmenu_icon);

            this.db.set_default_account (account);
            this.default_account = account;
            this.default_account_id = this.db.get_account_id ();

            this.set_widgets_sensitive (false);

            this.init_api ();
            switch_timeline ("loading");

            this.api.token = this.default_account.token;
            this.api.token_secret = this.default_account.token_secret;
            new Thread<void*> (null, this.init);
        }

        public void set_widgets_sensitive (bool sensitive) {
            this.new_tweet.set_sensitive (sensitive);
            this.home.set_sensitive (sensitive);
            this.mentions.set_sensitive (sensitive);
            this.dm.set_sensitive (sensitive);
            this.profile.set_sensitive (sensitive);
            this.search.set_sensitive (sensitive);
            this.account_appmenu.set_sensitive (sensitive);
            this.remove_appmenu.set_sensitive (sensitive);
        }

        public void switch_timeline (string new_timeline) {
            Idle.add( () => {
                this.changing_tab = true;

                bool active = false;

                if (this.current_timeline == new_timeline)
                    active = true;

                switch (current_timeline) {
                    case "home":
                        this.home.set_active (active);
                        break;
                    case "mentions":
                        this.mentions.set_active (active);
                        break;
                    case "dm":
                        this.dm.set_active (active);
                        break;
                    case "own":
                        this.profile.set_active (active);
                        break;
                    case "search":
                        this.search.set_active (active);
                        break;
                }

                this.changing_tab = false;

                switch (new_timeline) {
                    case "loading":
                        this.spinner.start ();
                        this.notebook.page = 0;
                        break;
                    case "welcome":
                        this.notebook.page = 1;
                        break;
                    case "home":
                        this.home_list.set_selectable (false);
                        this.notebook.page = 2;
                        this.home_list.set_selectable (true);
                        this.scrolled_home.get_vadjustment().set_value(0);
                        break;
                    case "mentions":
                        this.mentions_list.set_selectable (false);
                        this.notebook.page = 3;
                        this.mentions_list.set_selectable (true);
                        this.scrolled_mentions.get_vadjustment().set_value(0);
                        break;
                    case "dm":
                        this.dm_list.set_selectable (false);
                        this.dm_sent_list.set_selectable (false);
                        this.notebook.page = 4;
                        this.dm_list.set_selectable (true);
                        this.dm_sent_list.set_selectable (true);
                        this.scrolled_dm.get_vadjustment().set_value(0);
                        break;
                    case "own":
                        this.own_list.set_selectable (false);
                        this.notebook.page = 5;
                        this.own_list.set_selectable (true);
                        this.scrolled_own.get_vadjustment().set_value(0);
                        break;
                    case "user":
                        this.user_list.set_selectable (false);
                        this.notebook.page = 6;
                        this.user_list.set_selectable (true);
                        break;
                    case "search":
                        this.changing_tab = true;
                        this.search.set_active (true);
                        this.changing_tab = false;
                        this.notebook.page = 7;
                        break;
                    case "error":
                        this.set_widgets_sensitive (false);
                        this.notebook.page = 8;
                        break;
                }

                this.current_timeline = new_timeline;

                return false;
            });
        }

        /*

        GLib timeout methods

        */

        public void add_timeout_offline () {
            this.timerID_offline = GLib.Timeout.add_seconds (60, () => {
                new Thread<void*> (null, this.update_dates);
                return true;
            });
        }

        public void add_timeout_online () {
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
                this.update_home ();
                this.update_mentions ();
                this.update_dm ();
                get_avatar (this.home_list);
                get_avatar (this.mentions_list);
                get_avatar (this.dm_list);
            } else {
                this.switch_timeline ("error");
            }
            return null;
        }

        public void update_home () {
            this.api.get_home_timeline ();
            string notify_header = "";
            string notify_text = "";

            this.home_tmp.foreach ((tweet) => {
                this.home_list.remove (tweet);
                this.home_tmp.remove (tweet);
            });

            this.api.home_timeline.foreach ((tweet) => {
                this.home_list.append (tweet, this);
                this.db.add_user (tweet.user_screen_name,
                    tweet.user_name, this.default_account_id);
                if (this.tweet_notification) {
                    if ((this.api.account.screen_name != tweet.user_screen_name) &&
                            this.api.home_timeline.length () <= this.limit_notifications) {
                        notify_header = _("New tweet from") + " " + tweet.user_screen_name;
                        notify_text = tweet.text;
                    }
                    this.unread_tweets++;
                }
            });

            if (this.tweet_notification && this.api.home_timeline.length () <=
                this.limit_notifications  &&
                this.api.home_timeline.length () > 0) {
                    Utils.notify (notify_header, notify_text);
            }

            if (this.tweet_notification && this.api.home_timeline.length () > this.limit_notifications) {
                Utils.notify (this.unread_tweets.to_string () + " " + _("new tweets"), "");
            }

            if (this.tweet_notification && get_total_unread () > 0) {
                #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
                this.indicator.update_tweets_indicator (this.unread_tweets);
                #endif
                #if HAVE_LIBUNITY
                this.launcher.set_count (get_total_unread ());
                #endif
            }
        }

        public void update_mentions () {
            bool new_mentions = false;
            string notify_header = "";
            string notify_text = "";

            this.api.get_mentions_timeline ();

            this.api.mentions_timeline.foreach ((tweet) => {
                this.mentions_list.append (tweet, this);
                this.db.add_user (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                    if (this.mention_notification) {
                        if ((this.api.account.screen_name != tweet.user_screen_name) &&
                                this.api.mentions_timeline.length () <= this.limit_notifications) {
                            notify_header = _("New mention from") + " " + tweet.user_screen_name;
                            notify_text = tweet.text;
                        }
                    this.unread_mentions++;
                    new_mentions = true;
                }
            });

            if (this.tweet_notification && this.api.mentions_timeline.length () <=
                this.limit_notifications &&
                this.api.mentions_timeline.length () > 0) {
                    Utils.notify (notify_header, notify_text);
            }

            if (this.mention_notification && this.api.mentions_timeline.length () > this.limit_notifications) {
                Utils.notify (this.unread_mentions.to_string () + " " + _("new mentions"), "");
            }

            if (this.mention_notification && new_mentions) {
                #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
                this.indicator.update_mentions_indicator (this.unread_mentions);
                #endif
                #if HAVE_LIBUNITY
                this.launcher.set_count (get_total_unread ());
                #endif
            }
        }

        public void update_dm () {
            bool new_dms = false;
            string notify_header = "";
            string notify_text = "";

            this.api.get_direct_messages ();

            this.api.dm_timeline.foreach ((tweet) => {
                this.dm_list.append (tweet, this);
                this.db.add_user (tweet.user_screen_name,
                        tweet.user_name, this.default_account_id);
                if (this.dm_notification) {
                    if ((this.api.account.screen_name !=
                                tweet.user_screen_name) &&
                                this.api.dm_timeline.length () <=
                                this.limit_notifications) {
                        notify_header = _("New direct message from") + " " + tweet.user_screen_name;
                        notify_text = tweet.text;
                    }
                    this.unread_dm++;
                    new_dms = true;
                }
            });

            if (this.tweet_notification && this.api.dm_timeline.length () <=
                this.limit_notifications  &&
                this.api.dm_timeline.length () > 0) {
                    Utils.notify (notify_header, notify_text);
            }

            if (this.dm_notification && this.api.dm_timeline.length () > this.limit_notifications) {
                Utils.notify (this.unread_dm.to_string () + " " + _("new direct messages"), "");
            }

            if (this.dm_notification && new_dms) {
                #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
                this.indicator.update_dm_indicator (this.unread_dm);
                #endif
                #if HAVE_LIBUNITY
                this.launcher.set_count (get_total_unread ());
                #endif
            }
        }

        public void* update_dates () {
            this.home_list.update_date ();
            this.mentions_list.update_date ();
            return null;
        }

        private int get_total_unread () {
            return this.unread_tweets + this.unread_mentions + this.unread_dm;
        }

        /*

        Indicator cleaning

        */

        private void clean_tweets_indicator () {
            #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
            if (this.unread_tweets > 0)
                this.indicator.clean_tweets_indicator();
            #endif
            this.unread_tweets = 0;
        }

        private void clean_mentions_indicator () {
            #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
            if (this.unread_mentions > 0)
                this.indicator.clean_mentions_indicator();
            #endif
            this.unread_mentions = 0;
        }

        private void clean_dm_indicator () {
            #if HAVE_LIBINDICATE || HAVE_LIBMESSAGINGMENU
            if (this.unread_dm > 0)
                this.indicator.clean_dm_indicator();
            #endif
            this.unread_dm = 0;
        }

        /*

        Callback method for sending messages

        */

        public void tweet_callback (string text, string id = "",
            string user_screen_name, bool dm, string media_uri) {

            int64 code;
            var text_url = "";
            var media_out = "";

            if (this.check_internet_connection ()) {
                if (dm)
                    code = this.api.send_direct_message (user_screen_name, text);
                else
                    if (media_uri == "")
                        code = this.api.update (text, id);
                    else
                        code = this.api.update_with_media (text, id, media_uri, out media_out);

                if (code != 1) {
                    text_url = Utils.highlight_urls (text);

                    if (media_out != "") {
                        text_url = text_url + " <a href='" + media_out + "'>" + media_out + "</a>";
                    }

                    string user = user_screen_name;

                    if ("@" in user_screen_name)
                        user = user.replace ("@", "");

                    if (user == "")
                        user = this.api.account.screen_name;

                    Tweet tweet_tmp = new Tweet (code.to_string (), code.to_string (),
                        this.api.account.name, user, text_url, "", this.api.account.profile_image_url,
                        this.api.account.profile_image_file, false, false, dm);

                    if (dm) {
                        this.dm_sent_list.append (tweet_tmp, this);
                        this.switch_timeline ("dm");
                        Idle.add (() => {
                            this.notebook_dm.page = 1;
                            return false;
                        });
                        get_avatar (this.dm_sent_list);
                    } else {
                        this.home_tmp.append (tweet_tmp);
                        this.home_list.append (tweet_tmp, this);
                        this.own_list.append (tweet_tmp, this);

                        get_avatar (this.home_list);
                        get_avatar (this.own_list);

                        this.switch_timeline ("home");
                    }
                }
            } else {
                this.switch_timeline ("error");
            }
        }

        public void* show_user () {
            if (this.check_internet_connection ()) {
                Idle.add (() => {
                    this.switch_timeline ("loading");
                    return false;
                });

                this.api.user_timeline.foreach ((tweet) => {
                    this.user_list.remove (tweet);
                });

                this.api.get_user_timeline (user);

                this.api.user_timeline.foreach ((tweet) => {
                    this.user_list.append (tweet, this);
                });

                Idle.add (() => {
                    this.user_box_info.update (this.api.user);
                    get_userbox_avatar (this.user_box_info);
                    this.switch_timeline ("user");
                    this.spinner.stop ();
                    return false;
                });

                get_avatar (this.user_list);
            } else {
                this.switch_timeline ("error");
            }

            return null;
        }

        private void* show_search () {
            if (this.check_internet_connection ()) {
                this.api.search_timeline.foreach ((tweet) => {
                    this.search_list.remove (tweet);
                });

                Idle.add (() => {
                    this.switch_timeline ("loading");
                    search_entry.text = search_term;
                    return false;
                });

                this.api.get_search_timeline (search_term);

                Idle.add (() => {
                    this.spinner.stop ();
                    search_entry.text = search_term;
                    this.switch_timeline ("search");
                    return false;
                });

                this.api.search_timeline.foreach ((tweet) => {
                    this.search_list.append (tweet, this);
                });

                get_avatar (this.search_list);
            } else {
                this.switch_timeline ("error");
            }

            return null;
        }

        private bool check_internet_connection() {
            if (!Utils.check_internet_connection ()) {
                return false;
            }
            return true;
        }
    }
}
