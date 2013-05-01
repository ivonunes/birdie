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
    public class Birdie : Granite.Application {
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
        private Widgets.MenuPopOver menu;

        private Gtk.ToolButton new_tweet;
        private Gtk.ToggleToolButton home;
        private Gtk.ToggleToolButton mentions;
        private Gtk.ToggleToolButton dm;
        private Gtk.ToggleToolButton profile;
        private Gtk.ToggleToolButton search;
        private Granite.Widgets.ToolButtonWithMenu appmenu;

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

        private Granite.Widgets.Welcome welcome;
        private Granite.Widgets.Welcome error_page;

        private Granite.Widgets.StaticNotebook notebook;
        private Granite.Widgets.StaticNotebook notebook_dm;
        private Granite.Widgets.StaticNotebook notebook_own;
        private Granite.Widgets.StaticNotebook notebook_user;

        private Gtk.Spinner spinner;
        private Gtk.Entry pin_entry;

        private GLib.List<Tweet> home_tmp;

        private Gtk.CssProvider d_provider;

        public API api;

        public string current_timeline;

        private Utils.Indicator indicator;
        private Utils.Launcher launcher;

        private int unread_tweets;
        private int unread_mentions;
        private int unread_dm;

        public int service;

        private bool tweet_notification;
        private bool mention_notification;
        private bool dm_notification;
        private bool legacy_window;
        private int update_interval;

        private Regex urls;
        public Settings settings;

        private string user;
        private string search_term;

        private bool initialized;
        private bool changing_tab;

        construct {
            program_name        = "Birdie";
            exec_name           = "birdie";
            build_version       = Constants.VERSION;
            app_years           = "2013";
            app_icon            = "birdie";
            app_launcher        = "birdie.desktop";
            application_id      = "org.pantheon.birdie";
            main_url            = "http://www.launchpad.net/birdie";
            bug_url             = "http://bugs.launchpad.net/birdie";
            help_url            = "http://answers.launchpad.net/birdie";
            translate_url       = "http://translations.launchpad.net/birdie";
            about_authors       = {"Ivo Nunes <ivo@elementaryos.org>", "Vasco Nunes <vascomfnunes@gmail.com>"};
            about_artists       = {"Daniel Foré <daniel@elementaryos.org>", "Mustapha Asbbar"};
            /*about_comments      = "";
            about_documenters   = {};
            about_translators   = {};*/
            about_license_type  = Gtk.License.GPL_3_0;
        }

        public static const OptionEntry[] app_options = {
            { "start-hidden", 's', 0, OptionArg.NONE, out Option.START_HIDDEN, "Start hidden", null },
            { null }
        };

        public Birdie () {
            set_flags (ApplicationFlags.HANDLES_OPEN);
            this.initialized = false;
            this.changing_tab = false;

            // create cache dirs if needed
            string media_cache_path = Environment.get_home_dir () +
                    "/.cache/birdie/media";
            File media_cache = File.new_for_path (media_cache_path);
            if (media_cache.query_file_type (0) != FileType.DIRECTORY) {
                GLib.DirUtils.create_with_parents (media_cache_path, 0775);
            }
        }

        public override void activate (){
            if (get_windows () == null) {
                // settings
                this.settings = new Settings ("org.pantheon.birdie");
                this.service = settings.get_enum ("service");
                this.tweet_notification = settings.get_boolean ("tweet-notification");
                this.mention_notification = settings.get_boolean ("mention-notification");
                this.dm_notification = settings.get_boolean ("dm-notification");
                this.legacy_window = settings.get_boolean ("legacy-window");
                this.update_interval = settings.get_int ("update-interval");

                if (this.legacy_window)
                    this.m_window = new Widgets.UnifiedWindow ("Birdie", true);
                else
                    this.m_window = new Widgets.UnifiedWindow ();

                this.m_window.set_default_size (450, 600);
                this.m_window.set_size_request (430, 325);
                this.m_window.set_application (this);

                // restore main window size and position
                this.m_window.opening_x = settings.get_int ("opening-x");
                this.m_window.opening_y = settings.get_int ("opening-y");
                this.m_window.window_width = settings.get_int ("window-width");
                this.m_window.window_height = settings.get_int ("window-height");
                this.m_window.restore_window ();

                this.indicator = new Utils.Indicator (this);
                this.launcher = new Utils.Launcher (this);
                this.unread_tweets = 0;
                this.unread_mentions = 0;
                this.unread_dm = 0;

                var new_tweet_label = _("New Tweet");

                if (this.service == 1)
                    new_tweet_label = _("New Status");

                if (this.tweet_notification || this.mention_notification || this.dm_notification)
                    this.m_window.hide_on_delete ();

                this.new_tweet = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("mail-message-new", Gtk.IconSize.LARGE_TOOLBAR), new_tweet_label);
                new_tweet.set_tooltip_text (new_tweet_label);

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

                home.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("home");
                });
                this.home.set_sensitive (false);
                this.m_window.add_bar (home);

                this.mentions = new Gtk.ToggleToolButton ();
                this.mentions.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-mentions", Gtk.IconSize.LARGE_TOOLBAR));
                mentions.set_tooltip_text (_("Mentions"));

                mentions.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("mentions");
                });

                this.mentions.set_sensitive (false);
                this.m_window.add_bar (mentions);

                this.dm = new Gtk.ToggleToolButton ();
                this.dm.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-dm", Gtk.IconSize.LARGE_TOOLBAR));
                dm.set_tooltip_text (_("Direct Messages"));
                dm.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("dm");
                });
                this.dm.set_sensitive (false);
                this.m_window.add_bar (dm);

                this.profile = new Gtk.ToggleToolButton ();
                this.profile.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-profile", Gtk.IconSize.LARGE_TOOLBAR));
                profile.set_tooltip_text (_("Profile"));

                profile.toggled.connect (() => {
                    if (!this.changing_tab)
                        this.switch_timeline ("own");
                });
                this.profile.set_sensitive (false);
                this.m_window.add_bar (profile);

                this.search = new Gtk.ToggleToolButton ();
                this.search.set_icon_widget (new Gtk.Image.from_icon_name ("twitter-search", Gtk.IconSize.LARGE_TOOLBAR));
                search.set_tooltip_text (_("Search"));

                search.toggled.connect (() => {
                    if (!this.changing_tab) {
                        this.changing_tab = true;

                        switch (current_timeline) {
                            case "home":
                                this.home.set_active (false);
                                break;
                            case "mentions":
                                this.mentions.set_active (false);
                                break;
                            case "dm":
                                this.dm.set_active (false);
                                break;
                            case "own":
                                this.profile.set_active (false);
                                break;
                        }

                        var pop = new Granite.Widgets.PopOver ();

                        var search_entry = new Granite.Widgets.SearchBar (_("Search"));

                        search_entry.activate.connect (() => {
                            this.search_term = search_entry.get_text ();
                            new Thread<void*> (null, this.show_search);
                            pop.destroy ();
                        });

                        var pop_box = pop.get_content_area () as Gtk.Container;
                        pop_box.add (search_entry);

                        pop.set_parent_pop (m_window);
                        pop.move_to_widget (this.search);

                        pop.show_all ();
                        pop.present ();
                        pop.run ();
                        pop.destroy ();

                        switch (current_timeline) {
                            case "home":
                                this.home.set_active (true);
                                break;
                            case "mentions":
                                this.mentions.set_active (true);
                                break;
                            case "dm":
                                this.dm.set_active (true);
                                break;
                            case "own":
                                this.profile.set_active (true);
                                break;
                        }

                        this.search.set_active (false);
                        this.changing_tab = false;
                    }
                });
                this.search.set_sensitive (false);
                this.m_window.add_bar (search);

                var right_sep = new Gtk.SeparatorToolItem ();
                right_sep.draw = false;
                right_sep.set_expand (true);
                this.m_window.add_bar (left_sep);

                menu = new Widgets.MenuPopOver ();
                this.account_appmenu = new Gtk.MenuItem.with_label (_("Account Settings"));
                account_appmenu.activate.connect (() => {
                    this.new_tweet.set_sensitive (false);
                    this.home.set_sensitive (false);
                    this.mentions.set_sensitive (false);
                    this.dm.set_sensitive (false);
                    this.profile.set_sensitive (false);
                    this.search.set_sensitive (false);
                    this.account_appmenu.set_sensitive (false);

                    this.settings.set_string ("token", "");
                    this.settings.set_string ("token-secret", "");

                    this.api.home_timeline.foreach ((tweet) => {
                        this.home_list.remove (tweet);
                    });

                    this.api.mentions_timeline.foreach ((tweet) => {
                        this.mentions_list.remove (tweet);
                    });

                    this.api.dm_timeline.foreach ((tweet) => {
                        this.dm_list.remove (tweet);
                    });

                    this.api.dm_sent_timeline.foreach ((tweet) => {
                        this.dm_sent_list.remove (tweet);
                    });

                    this.api.own_timeline.foreach ((tweet) => {
                        this.own_list.remove (tweet);
                    });

                    this.api.favorites.foreach ((tweet) => {
                        this.favorites.remove (tweet);
                    });

                    init_api ();
                    this.switch_timeline ("welcome");
                });
                this.account_appmenu.set_sensitive (false);
                var about_appmenu = new Gtk.MenuItem.with_label (_("About"));
                about_appmenu.activate.connect (() => {
                    show_about (this.m_window);
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
                menu.add (about_appmenu);
                menu.add (quit_appmenu);
                this.appmenu = new Granite.Widgets.ToolButtonWithMenu (new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU), _("Menu"), menu);
                menu.move_to_widget (appmenu);

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

                this.welcome = new Granite.Widgets.Welcome (_("Birdie"), _("Twitter Client"));
                this.welcome.append ("twitter", _("Add account"), _("Add a Twitter account"));
                this.welcome.activated.connect (() => {
                    new Thread<void*> (null, this.request);
                });

                this.error_page = new Granite.Widgets.Welcome (_("Unable to connect"), _("Please check your Internet Connection"));
                this.error_page.append ("view-refresh", _("Retry"), _("Try to connect again"));
                this.error_page.activated.connect (() => {
                    this.new_tweet.set_sensitive (true);
                    this.home.set_sensitive (true);
                    this.mentions.set_sensitive (true);
                    this.dm.set_sensitive (true);
                    this.profile.set_sensitive (true);
                    this.search.set_sensitive (true);
                    this.account_appmenu.set_sensitive (true);

                    if (this.initialized) {
                        this.switch_timeline ("loading");
                        this.spinner.start ();
                        this.switch_timeline ("home");
                        new Thread<void*> (null, this.update_timelines);
                    } else {
                        this.switch_timeline ("loading");
                        this.spinner.start ();
                        new Thread<void*> (null, this.init);
                    }
                });

                this.notebook_dm = new Granite.Widgets.StaticNotebook (false);
                this.notebook_dm.append_page (this.scrolled_dm, new Gtk.Label (_("Received")));
                this.notebook_dm.append_page (this.scrolled_dm_sent, new Gtk.Label (_("Sent")));

                this.notebook = new Granite.Widgets.StaticNotebook ();
                this.notebook.set_switcher_visible (false);
                this.notebook.get_style_context ().add_class (Granite.StyleClass.CONTENT_VIEW);

                this.spinner = new Gtk.Spinner ();
                this.spinner.set_size_request (32, 32);
                this.spinner.start ();

                Gtk.Box spinner_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                spinner_box.pack_start (new Gtk.Label (""), true, true, 0);
                spinner_box.pack_start (this.spinner, false, false, 0);
                spinner_box.pack_start (new Gtk.Label (""), true, true, 0);

                this.pin_entry = new Gtk.Entry ();
                Gtk.Box pin_entry_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                pin_entry_box.pack_start (new Gtk.Label (""), true, true, 0);
                pin_entry_box.pack_start (this.pin_entry);
                pin_entry_box.pack_start (new Gtk.Label (""), true, true, 0);

                Gtk.Button pin_button = new Gtk.Button.with_label (_("OK"));
                pin_button.clicked.connect (() => {
                    new Thread<void*> (null, this.tokens);
                });
                Gtk.Box pin_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
                pin_button_box.pack_start (new Gtk.Label (""), true, true, 0);
                pin_button_box.pack_start (pin_button);
                pin_button_box.pack_start (new Gtk.Label (""), true, true, 0);

                Gtk.Box pin_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                pin_box.pack_start (new Gtk.Label (""), true, true, 0);
                pin_box.pack_start (new Gtk.Label (_("Please insert your PIN below:")), false, false, 0);
                pin_box.pack_start (new Gtk.Label (""), false, false, 0);
                pin_box.pack_start (pin_entry_box, false, false, 0);
                pin_box.pack_start (new Gtk.Label (""), false, false, 0);
                pin_box.pack_start (pin_button_box, false, false, 0);
                pin_box.pack_start (new Gtk.Label (""), true, true, 0);

                this.init_api ();

                this.own_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                this.own_box_info = new Widgets.UserBox ();
                this.own_box.pack_start (this.own_box_info, false, false, 0);
                this.scrolled_favorites.add_with_viewport (this.favorites);
                this.scrolled_own.add_with_viewport (this.own_list);

                this.notebook_own = new Granite.Widgets.StaticNotebook (true);
                this.notebook_own.append_page (this.scrolled_own, new Gtk.Label (_("Timeline")));
                this.notebook_own.append_page (this.scrolled_favorites, new Gtk.Label (_("Favorites")));
                this.own_box.pack_start (this.notebook_own, true, true, 0);

                this.user_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
                this.user_box_info = new Widgets.UserBox ();
                this.notebook_user = new Granite.Widgets.StaticNotebook (true);
                this.notebook_user.append_page (this.scrolled_user, new Gtk.Label (_("Timeline")));
                this.user_box.pack_start (this.user_box_info, false, false, 0);

                // separator
                this.user_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
                this.user_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);

                this.user_box.pack_start (this.notebook_user, true, true, 0);

                this.notebook.append_page (spinner_box, new Gtk.Label (_("Loading")));
                this.notebook.append_page (this.welcome, new Gtk.Label (_("Welcome")));
                this.notebook.append_page (pin_box, new Gtk.Label (_("Welcome")));
                this.notebook.append_page (this.scrolled_home, new Gtk.Label (_("Home")));
                this.notebook.append_page (this.scrolled_mentions, new Gtk.Label (_("Mentions")));
                this.notebook.append_page (this.notebook_dm, new Gtk.Label (_("Direct Messages")));
                this.notebook.append_page (this.own_box, new Gtk.Label (_("Profile")));
                this.notebook.append_page (this.user_box, new Gtk.Label (_("User")));
                this.notebook.append_page (this.scrolled_search, new Gtk.Label (_("Search Results")));
                this.notebook.append_page (this.error_page, new Gtk.Label (_("Error")));

                this.m_window.add (this.notebook);

                // css provider

                d_provider = new Gtk.CssProvider ();
                string css_dir = Constants.DATADIR + "/birdie";
                File file = File.new_for_path (css_dir);
                File child = file.get_child ("birdie.css");

                bool elementary = false;

                var lsb = File.new_for_path ("/etc/lsb-release");

                if (lsb.query_exists ()) {
                    try {
                        var dis = new DataInputStream (lsb.read ());
                        string line;
                        while ((line = dis.read_line (null)) != null) {
                            if ("elementary" in line) {
                                elementary = true;
                            }
                        }
                    } catch (Error e) {
                        error ("%s", e.message);
                    }

                }

                if (elementary) {
                    try
                    {
                        d_provider.load_from_file (child);
                    }
                    catch (GLib.Error error)
                    {
                        stderr.printf("Could not load css for birdie: %s", error.message);
                    }
                }

                Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default(), d_provider, 600);
                Gtk.StyleContext ctx = m_window.get_style_context();
                ctx.add_class("main_window");
                //

                this.m_window.focus_in_event.connect ((w, e) => {
                    this.launcher.clean_launcher_count ();

                    switch (this.current_timeline) {
                        case "home":
                            this.unread_tweets = 0;
                            this.indicator.clean_tweets_indicator();
                            break;
                        case "mentions":
                            this.unread_mentions = 0;
                            this.indicator.clean_mentions_indicator();
                            break;
                        case "dm":
                            this.unread_dm = 0;
                            this.indicator.clean_dm_indicator();
                            break;
                    }

                    return true;
                });

                this.m_window.show_all ();
                this.own_box_info.hide_buttons ();

                if (Option.START_HIDDEN) {
                    this.m_window.hide ();
                }

                if (this.api.token == "" || this.api.token_secret == "") {
                    this.switch_timeline ("welcome");
                } else {
                    new Thread<void*> (null, this.init);
                }
            } else {
                this.m_window.show_all ();
                this.own_box_info.hide_buttons ();
                this.m_window.present ();
                this.launcher.clean_launcher_count ();

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
                        this.unread_tweets = 0;
                        this.indicator.clean_tweets_indicator();
                        break;
                    case "mentions":
                        this.unread_mentions = 0;
                        this.indicator.clean_mentions_indicator();
                        break;
                    case "dm":
                        this.unread_dm = 0;
                        this.indicator.clean_dm_indicator();
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

        private void* request () {
            this.switch_timeline ("pin");
            try {
                GLib.Process.spawn_command_line_async ("x-www-browser \"" + this.api.get_request () + "\"");
            } catch (GLib.Error error) {
                warning ("error opening url: %s", error.message);
            }
            return null;
        }

        private void* tokens () {
            this.switch_timeline ("loading");

            int code = this.api.get_tokens (this.pin_entry.get_text ());

            if (code == 0) {
                new Thread<void*> (null, this.init);
            } else {
                this.switch_timeline ("welcome");
            }

            return null;
        }

        private void* init () {
            if (this.check_internet_connection ()) {
                this.api.auth ();
                this.api.get_account ();
                this.api.get_home_timeline ();
                this.api.get_mentions_timeline ();
                this.api.get_direct_messages ();
                this.api.get_direct_messages_sent ();
                this.api.get_own_timeline ();
                this.api.get_favorites ();

                this.api.home_timeline.foreach ((tweet) => {
                    this.home_list.append(tweet, this);
                });

                this.api.mentions_timeline.foreach ((tweet) => {
                    this.mentions_list.append(tweet, this);
                });

                this.api.dm_timeline.foreach ((tweet) => {
                    this.dm_list.append(tweet, this);
                });

                this.api.dm_sent_timeline.foreach ((tweet) => {
                    this.dm_sent_list.append(tweet, this);
                });

                this.api.own_timeline.foreach ((tweet) => {
                    this.own_list.append(tweet, this);
                });

                this.api.favorites.foreach ((tweet) => {
                    this.favorites.append(tweet, this);
                });

                Idle.add (() => {
                    if (this.initialized) {
                        this.own_box_info.update (this.api.account);
                        this.user_box_info.update (this.api.account);

                        this.own_box_info.hide_buttons ();
                    } else {
                        this.own_box_info.init (this.api.account, this);
                        this.user_box_info.init (this.api.account, this);
                    }
                    
                    var avatar_pixbuf = new Gdk.Pixbuf.from_file_at_scale (Environment.get_home_dir () + "/.cache/birdie/" + this.api.account.profile_image_file, 24, 24, true);
                    var avatar_image = new Gtk.Image.from_pixbuf (avatar_pixbuf);
                    avatar_image.show ();
                    this.appmenu.set_icon_widget (avatar_image);
                    
                    var avatar_image_menu = new Gtk.Image.from_file (Environment.get_home_dir () + "/.cache/birdie/" + this.api.account.profile_image_file);
                    var account_menu_item = new Gtk.ImageMenuItem.with_label (this.api.account.name + "\n@" + this.api.account.screen_name);
                    
                    foreach (var child in account_menu_item.get_children ()) {
                        if (child is Gtk.Label)
                            ((Gtk.Label)child).set_markup ("<b>" + this.api.account.name + "</b>\n@" + this.api.account.screen_name);
                    }
                    
                    account_menu_item.set_image (avatar_image_menu);
                    account_menu_item.set_always_show_image (true);
                    
                    this.menu.prepend (new Gtk.SeparatorMenuItem ());
                    this.menu.prepend (account_menu_item);
                    this.menu.show_all ();

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
            } else {
                this.switch_timeline ("error");
            }

            return null;
        }

        private void init_api () {
            if (this.service == 0)
                this.api = new Twitter ();
            else
                this.api = new Identica ();
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
                    case "search_results":
                        this.search.set_active (active);
                        break;
                }

                this.changing_tab = false;

                switch (new_timeline) {
                    case "loading":
                        this.notebook.page = 0;
                        break;
                    case "welcome":
                        this.notebook.page = 1;
                        break;
                    case "pin":
                        this.notebook.page = 2;
                        break;
                    case "home":
                        this.home_list.set_selectable (false);
                        this.notebook.page = 3;
                        this.home_list.set_selectable (true);
                        this.scrolled_home.get_vadjustment().set_value(0);
                        break;
                    case "mentions":
                        this.mentions_list.set_selectable (false);
                        this.notebook.page = 4;
                        this.mentions_list.set_selectable (true);
                        this.scrolled_mentions.get_vadjustment().set_value(0);
                        break;
                    case "dm":
                        this.dm_list.set_selectable (false);
                        this.dm_sent_list.set_selectable (false);
                        this.notebook.page = 5;
                        this.dm_list.set_selectable (true);
                        this.dm_sent_list.set_selectable (true);
                        this.scrolled_dm.get_vadjustment().set_value(0);
                        break;
                    case "own":
                        this.own_list.set_selectable (false);
                        this.notebook.page = 6;
                        this.own_list.set_selectable (true);
                        this.scrolled_own.get_vadjustment().set_value(0);
                        break;
                    case "user":
                        this.user_list.set_selectable (false);
                        this.notebook.page = 7;
                        this.user_list.set_selectable (true);
                        break;
                    case "search_results":
                        this.changing_tab = true;
                        this.search.set_active (true);
                        this.changing_tab = false;
                        this.notebook.page = 8;
                        break;
                    case "error":
                        this.new_tweet.set_sensitive (false);
                        this.home.set_sensitive (false);
                        this.mentions.set_sensitive (false);
                        this.dm.set_sensitive (false);
                        this.profile.set_sensitive (false);
                        this.search.set_sensitive (false);
                        this.account_appmenu.set_sensitive (false);
                        this.notebook.page = 9;
                        break;
                }

                this.current_timeline = new_timeline;

                return false;
            });
        }

        public void add_timeout_offline () {
            GLib.Timeout.add_seconds (60, () => {
                new Thread<void*> (null, this.update_dates);
                return false;
            });
        }

        public void add_timeout_online () {
            GLib.Timeout.add_seconds (this.update_interval * 60, () => {
                new Thread<void*> (null, this.update_timelines);
                return false;
             });
        }

        public void* update_dates () {
            this.home_list.update_date ();
            this.mentions_list.update_date ();
            this.add_timeout_offline ();
            return null;
        }

        public void* update_timelines () {
            if (this.check_internet_connection ()) {
                this.update_home ();
                this.update_mentions ();
                this.update_dm ();
            } else {
                this.switch_timeline ("error");
            }
            this.add_timeout_online ();
            return null;
        }

        public void update_home () {
            this.api.get_home_timeline ();

            this.home_tmp.foreach ((tweet) => {
                this.home_list.remove (tweet);
                this.home_tmp.remove (tweet);
            });

            this.api.home_timeline.foreach ((tweet) => {
                this.home_list.append (tweet, this);
                if (this.tweet_notification) {
                    if (this.api.account.screen_name != tweet.user_screen_name) {
                        Utils.notify ("New tweet from " + tweet.user_name, tweet.text);
                    }
                    this.unread_tweets++;
                }
            });

            if (this.tweet_notification) {
                this.indicator.update_tweets_indicator (this.unread_tweets);
                this.launcher.set_count (this.unread_tweets + this.unread_mentions + this.unread_dm);
            }
        }

        public void update_mentions () {

            this.api.get_mentions_timeline ();

            this.api.mentions_timeline.foreach ((tweet) => {
                this.mentions_list.append (tweet, this);
                if (this.mention_notification) {
                    if (this.api.account.screen_name != tweet.user_screen_name) {
                        Utils.notify ("New mention from " + tweet.user_name, tweet.text);
                    }
                    this.unread_mentions++;
                }
            });

            if (this.mention_notification) {
                this.indicator.update_mentions_indicator (this.unread_mentions);
                this.launcher.set_count (this.unread_tweets + this.unread_mentions + this.unread_dm);
            }
        }

        public void update_dm () {

            this.api.get_direct_messages ();

            this.api.dm_timeline.foreach ((tweet) => {
                this.dm_list.append (tweet, this);
                if (this.dm_notification) {
                    if (this.api.account.screen_name != tweet.user_screen_name) {
                        Utils.notify ("New direct message from " + tweet.user_name, tweet.text);
                    }
                    this.unread_dm++;
                }
            });

            if (this.dm_notification) {
                this.indicator.update_dm_indicator (this.unread_dm);
                this.launcher.set_count (this.unread_tweets + this.unread_mentions + this.unread_dm);
            }
        }

        public void tweet_callback (string text, string id = "", string user_screen_name, bool dm, string media_uri) {
            int64 code;
            var text_url = "";
            var media_out = "";

            if (dm)
                code = this.api.send_direct_message (user_screen_name, text);
            else
                if (media_uri == "")
                    code = this.api.update (text, id);
                else
                    code = this.api.update_with_media (text, id, media_uri, out media_out);

            try {
                urls = new Regex("((http|https|ftp)://([\\S]+))");
            } catch (RegexError e) {
                warning ("regex error: %s", e.message);
            }

            try {
                text_url = urls.replace(text, -1, 0, "<a href='\\0'>\\0</a>");
            } catch (Error e) {
                warning ("url replacing error: %s", e.message);
            }

            if (media_out != "") {
                text_url = text_url + " <a href='" + media_out + "'>" + media_out + "</a>";
            }

            string user = user_screen_name;

            if ("@" in user_screen_name)
                user = user.replace ("@", "");

            if (user == "")
                user = this.api.account.screen_name;

            if (code != 1) {
                Tweet tweet_tmp = new Tweet (code.to_string (), code.to_string (), this.api.account.name, user, text_url, "", this.api.account.profile_image_url, this.api.account.profile_image_file, false, false, dm);

                if (dm) {
                    this.dm_sent_list.append (tweet_tmp, this);
                    this.switch_timeline ("dm");
                    Idle.add (() => {
                        this.notebook_dm.page = 1;
                        return false;
                    });
                } else {
                    this.home_tmp.append (tweet_tmp);
                    this.home_list.append (tweet_tmp, this);
                    this.own_list.append (tweet_tmp, this);
                    this.favorites.append (tweet_tmp, this);

                    this.switch_timeline ("home");
                }
            }
        }

        private void* show_user () {
            if (this.check_internet_connection ()) {
                Idle.add (() => {
                    this.switch_timeline ("loading");
                    this.spinner.start ();
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
                    this.switch_timeline ("user");
                    this.spinner.stop ();
                    return false;
                });
            } else {
                this.switch_timeline ("error");
            }

            return null;
        }

        private void* show_search () {
            if (this.check_internet_connection ()) {
                Idle.add (() => {
                    this.switch_timeline ("loading");
                    this.spinner.start ();
                    return false;
                });

                this.api.search_timeline.foreach ((tweet) => {
                    this.search_list.remove (tweet);
                });

                this.api.get_search_timeline (search_term);

                this.api.search_timeline.foreach ((tweet) => {
                    this.search_list.append (tweet, this);
                });

                Idle.add (() => {
                    this.switch_timeline ("search_results");
                    this.spinner.stop ();
                    return false;
                });
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
