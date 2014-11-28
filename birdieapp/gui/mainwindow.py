# -*- coding: utf-8 -*-

# Copyright (C) 2013-2014  Ivo Nunes/Vasco Nunes

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

from birdieapp.constants import APP_NAME, NEW_TWEET_ICON_NAME
from birdieapp.constants import MENTIONS_ICON_NAME, HOME_ICON_NAME, DM_ICON_NAME
from birdieapp.constants import PROFILE_ICON_NAME, SEARCH_ICON_NAME
from birdieapp.gui.aboutdialog import AboutDialog
from birdieapp.gui.userbox import UserBox
from birdieapp.gui.welcome import Welcome
from birdieapp.settings import Settings
from birdieapp.signalobject import SignalObject
from birdieapp.utils.system import detect_desktop_environment
from gi.repository import Gtk, Gdk
import gettext
import webbrowser


_ = gettext.gettext


class MainWindow(Gtk.Window, SignalObject):

    """Build the main window"""
    __gtype_name__ = "MainWindow"

    vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

    def __init__(self, settings):
        super(MainWindow, self).__init__()
        super(MainWindow, self).init_signals()

        self.settings = Settings()

        self.connect("delete-event", self.on_delete_event)
        self.set_size_request(580, 600)
        self.set_wmclass (APP_NAME, APP_NAME)
        self.set_title (APP_NAME)

        self.add_events(Gdk.EventMask.SMOOTH_SCROLL_MASK)

        # header_bar
        self.header_bar = Gtk.HeaderBar()
        self.header_bar.set_title(APP_NAME)
        self.set_for_desktop_environment()

        # widgets
        self.home_scrolled = Gtk.ScrolledWindow(None, None)
        self.activity_scrolled = Gtk.ScrolledWindow(None, None)
        self.dm_inbox_scrolled = Gtk.ScrolledWindow(None, None)
        self.dm_outbox_scrolled = Gtk.ScrolledWindow(None, None)
        self.tweets_scrolled = Gtk.ScrolledWindow(None, None)
        self.favorites_scrolled = Gtk.ScrolledWindow(None, None)
        self.lists_scrolled = Gtk.ScrolledWindow(None, None)
        self.search_scrolled = Gtk.ScrolledWindow(None, None)
        self.users_scrolled = Gtk.ScrolledWindow(None, None)

        self.home = Gtk.RadioToolButton.new(group=None)
        self.home_img = Gtk.Image()

        self.mentions = Gtk.RadioToolButton.new_from_widget(group=self.home)
        self.mentions_img = Gtk.Image()
        self.mentions_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        self.stack = Gtk.Stack()
        self.dm_stack = Gtk.Stack()
        self.activity_stack = Gtk.Stack()
        self.profile_stack = Gtk.Stack()
        self.users_profile_stack = Gtk.Stack()

        self.profile = Gtk.RadioToolButton.new_from_widget(group=self.home)
        self.profile_img = Gtk.Image()
        self.users_profile_img = Gtk.Image()

        self.menu = Gtk.Menu()
        self.menu_btn = Gtk.MenuButton()
        self.menu_btn_img = Gtk.Image()
        self.menu_btn.set_image(self.menu_btn_img)

        self.search_box = Gtk.Box()
        self.searchbar = Gtk.SearchBar()
        self.search_entry = Gtk.SearchEntry()
        self.search = Gtk.ToggleToolButton.new()
        self.search_img = Gtk.Image()

        self.dm = Gtk.RadioToolButton.new_from_widget(group=self.home)
        self.dm_img = Gtk.Image()
        self.inactive_menu = Gtk.RadioToolButton.new_from_widget(group=self.home)
        self.centered_toolbar = Gtk.Box()

        self.new_tweet = Gtk.ToolButton()
        self.new_tweet_img = Gtk.Image()

        self.profile_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.welcome = Welcome()
        
        # settings
        self.settings = settings
        self.restore_geometry()

        # prefer dark theme if key is set
        if self.settings.get("dark_theme") == 'true':
            Gtk.Settings.get_default().set_property(
                "gtk-application-prefer-dark-theme", True)

        self.fill_headerbar()
        self.show_all()

    def add_widget(self, widget, expanded=True):
        self.vbox.pack_start(widget, expanded, expanded, 0)

    def set_for_desktop_environment(self):
        """Setting titlebar for different environments"""
        #TODO: should we detect and act accordingly or always use the header bar?
        #if (detect_desktop_environment() == 'gnome'
        #        or detect_desktop_environment() == 'cinnamon'
        #        or self.settings.get("window_titlebar") == 'false'):
        #    self.header_bar.set_show_close_button(True)
        #    self.set_titlebar(self.header_bar)
        #else:
        #    self.header_bar.set_show_close_button(False)
        #    self.vbox.pack_start(self.header_bar, False, False, 0)
        self.header_bar.set_show_close_button(True)
        self.set_titlebar(self.header_bar)

        self.add(self.vbox)

    def fill_headerbar(self):
        """Build all the header_bar buttons"""

        # statusbar
        self.statusbar = Gtk.Statusbar.new()
        self.status_bar_context_id = self.statusbar.get_context_id("birdie")

        # new tweet button
        self.new_tweet_img.set_from_icon_name(
            NEW_TWEET_ICON_NAME, Gtk.IconSize.LARGE_TOOLBAR)
        self.new_tweet.set_icon_widget(self.new_tweet_img)
        self.new_tweet.set_tooltip_text('New Tweet')
        self.header_bar.pack_start(self.new_tweet)

        # Stack widget
        self.stack.set_transition_type(
            Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        self.stack.set_transition_duration(500)

        # home
        self.home_img.set_from_icon_name(HOME_ICON_NAME, Gtk.IconSize.LARGE_TOOLBAR)
        self.home.set_tooltip_text(_('Home'))
        self.home.set_icon_widget(self.home_img)
        self.centered_toolbar.add(self.home)
        self.stack.add_named(self.home_scrolled, "home")
        self.home.connect("clicked", self.on_home)

        # mentions
        self.mentions_img.set_from_icon_name(
            MENTIONS_ICON_NAME, Gtk.IconSize.LARGE_TOOLBAR)
        self.mentions.set_tooltip_text(_('Activity'))
        self.mentions.set_icon_widget(self.mentions_img)
        self.centered_toolbar.add(self.mentions)
        self.stack.add_named(self.activity_scrolled, "activity")
        self.mentions.connect("clicked", self.on_mentions)

        # dm
        self.dm_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.dm_stack.add_titled(
            self.dm_inbox_scrolled, "inbox", _("Received"))
        self.dm_stack.add_titled(self.dm_outbox_scrolled, "outbox", _("Sent"))
        self.dm_stack_switcher = Gtk.StackSwitcher(True)
        self.dm_stack_switcher.set_stack(self.dm_stack)
        self.dm_stack_switcher.set_margin_left(12)
        self.dm_stack_switcher.set_margin_right(12)
        self.dm_box.pack_start(self.dm_stack_switcher, False, False, 12)
        self.dm_box.pack_start(self.dm_stack, True, True, 0)

        self.dm_img.set_from_icon_name(DM_ICON_NAME, Gtk.IconSize.LARGE_TOOLBAR)
        self.dm.set_tooltip_text(_('Direct Messages'))
        self.dm.set_icon_widget(self.dm_img)
        self.centered_toolbar.add(self.dm)
        self.dm.connect("clicked", self.on_dm)
        self.stack.add_named(self.dm_box, "dm")

        # own profile
        self.profile_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.user_box = UserBox()
        self.profile_box.pack_start(self.user_box, False, False, 0)
        self.profile_stack.add_titled(self.tweets_scrolled,
                                      "tweets", _("Tweets"))
        self.profile_stack.add_titled(self.favorites_scrolled,
                                      "favorites", _("Favorites"))
        self.profile_stack.add_titled(self.lists_scrolled,
                                      "lists", _("Lists"))
        self.profile_stack_switcher = Gtk.StackSwitcher(True)
        self.profile_stack_switcher.set_stack(self.profile_stack)
        self.profile_stack_switcher.set_margin_left(12)
        self.profile_stack_switcher.set_margin_right(12)
        self.profile_box.pack_start(self.profile_stack_switcher,
                                    False, False, 12)
        self.profile_box.pack_start(self.profile_stack, True, True, 0)

        self.profile_img.set_from_icon_name(
            PROFILE_ICON_NAME, Gtk.IconSize.LARGE_TOOLBAR)
        self.profile.set_tooltip_text(_('Profile'))
        self.profile.set_icon_widget(self.profile_img)
        self.centered_toolbar.add(self.profile)
        self.stack.add_named(self.profile_box, "profile")
        self.profile.connect("clicked", self.on_profile)

        # users profile
        self.users_profile_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.users_box = UserBox()
        self.users_profile_box.pack_start(self.users_box, False, False, 0)
        self.users_profile_box.pack_start(self.users_scrolled, True, True, 0)
        self.users_profile_img.set_from_icon_name(PROFILE_ICON_NAME,
                                                  Gtk.IconSize.LARGE_TOOLBAR)
        self.stack.add_named(self.users_profile_box, "users_profile")

        # searchbar
        self.search_entry.connect("activate", self.on_search)
        self.searchbar.add(self.search_entry)
        self.vbox.pack_start(self.searchbar, False, False, 0)
        self.search_img.set_from_icon_name(
            SEARCH_ICON_NAME, Gtk.IconSize.LARGE_TOOLBAR)
        self.search.set_tooltip_text(_('Search'))
        self.search.set_icon_widget(self.search_img)
        self.search.bind_property("active", self.searchbar,
                                  "search-mode-enabled")

        self.centered_toolbar.add(self.search)

        # search box
        self.stack.add_named(self.search_scrolled, "search")

        self.header_bar.set_custom_title(self.centered_toolbar)

        # menu
        self.header_bar.pack_end(self.menu_btn)

        # menu items
        self.add_separator()
        self.append_menu_item(
            lambda x: self.on_add_account(), _("Add account"))
        self.append_menu_item(
            lambda x: self.on_remove_account(), _("Remove account"))
        self.add_separator()
        self.append_menu_item(lambda x: AboutDialog(self), _("About"))
        self.append_menu_item(lambda x: self.on_donations(), _("Donations"))
        self.append_menu_item(
            lambda x: self.on_exit_event(None, None), _("Exit"))

        self.menu_btn.set_popup(self.menu)
        self.menu_btn.set_relief(Gtk.ReliefStyle.NONE)

        self.add_widget(self.stack)
        self.add_widget(self.statusbar, False)
        self.statusbar.set_no_show_all(True)
        self.statusbar.hide()

        # welcome
        self.stack.add_named(self.welcome, "welcome")

    def add_account_menu(self, accounts, cb):
        for account in accounts:
            self.prepend_menu_item(cb, account.name, account.screen_name)

    def append_menu_item(self, command, title):
        menu_item = Gtk.MenuItem()
        menu_item.set_label(title)
        menu_item.connect("activate", command)
        self.menu.append(menu_item)
        self.menu.show_all()

    def prepend_menu_item(self, command, title, identifier=None):
        menu_item = Gtk.MenuItem()
        menu_item.set_label(title)
        menu_item.connect("activate", lambda w: command(identifier))
        self.menu.prepend(menu_item)
        self.menu.show_all()

    def add_separator(self):
        menu_item = Gtk.SeparatorMenuItem()
        self.menu.append(menu_item)
        self.menu.show_all()

    def restore_geometry(self):
        """Restore main window geometry from dconf"""
        self.move(self.settings.getint("x"), self.settings.getint("y"))
        self.set_default_size(
            self.settings.getint("width"), self.settings.getint("height"))
        pass

    def store_geometry(self):
        """Store main window geometry in dconf"""
        x, y = self.get_position()
        width, height = self.get_size()
        self.settings.write("x", x)
        self.settings.write("y", y)
        self.settings.write("width", width)
        self.settings.write("height", height)

    def toggle_visibility(self):
        self.hide() if self.get_visible() else self.present()

    def toggle_sensitivity(self):
        self.header_bar.set_sensitive(False) \
            if self.header_bar.get_sensitive() \
            else self.header_bar.set_sensitive(True)

    def deselect_all_buttons(self):
        self.inactive_menu.set_active(True)
        # for w in self.home.get_group():
        #    print w
            #GLib.idle_add(lambda: w.set_active(False))

    def twitter_down(self):
        self.statusbar.push(self.status_bar_context_id,
                            _("Connectivity lost. Will keep retrying."))
        self.statusbar.set_no_show_all(False)
        self.statusbar.show()

    def twitter_up(self):
        self.statusbar.remove_all(self.status_bar_context_id)
        self.statusbar.set_no_show_all(True)
        self.statusbar.hide()

    # EVENTS HANDLING

    def on_delete_event(self, widget, event, data=None):
        """Delete event signal callback"""
        if self.settings.get("hide_on_close") == "true":
            self.store_geometry()
            self.hide_on_delete()
        else:
            self.on_exit_event(None, None)
        return True

    def on_exit_event(self, widget, event, data=None):
        """Exit event signal callback"""
        self.emit_signal("exit")

    def on_add_account(self):
        self.welcome.on_signin(self.welcome)

    def on_remove_account(self):
        print("remove account triggered")
        # TODO

    def on_search(self, search_entry):
        self.emit_signal_with_args("search", (None, search_entry.get_text()))

    def on_home(self, _):
        self.stack.set_visible_child(self.home_scrolled)
        adj = self.home_scrolled.get_vadjustment()
        adj.set_value(0)

    def on_mentions(self, _):
        self.stack.set_visible_child(self.activity_scrolled)
        adj = self.activity_scrolled.get_vadjustment()
        adj.set_value(0)
        self.mentions_img.set_from_icon_name('twitter-mentions', Gtk.IconSize.LARGE_TOOLBAR)

    def on_dm(self, _):
        self.stack.set_visible_child(self.dm_box)
        adj = self.dm_inbox_scrolled.get_vadjustment()
        adj.set_value(0)
        self.dm_img.set_from_icon_name('twitter-dm', Gtk.IconSize.LARGE_TOOLBAR)

    def on_profile(self, _):
        self.stack.set_visible_child(self.profile_box)
        adj = self.tweets_scrolled.get_vadjustment()
        adj.set_value(0)

    def connect_add_account(self, cb):
        self.welcome.connect_signin(cb)

    @staticmethod
    def on_donations():
        webbrowser.open('http://birdieapp.github.io/donate', new=2)
