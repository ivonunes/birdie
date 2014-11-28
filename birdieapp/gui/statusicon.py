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


from gi.repository import Gtk
from birdieapp.signalobject import SignalObject


class StatusIcon(SignalObject):

    def __init__(self):
        super(StatusIcon, self).init_signals()

        self.statusicon = Gtk.StatusIcon()
        self.statusicon.set_from_icon_name("birdie")
        self.statusicon.connect("popup-menu", self.right_click_event)
        self.statusicon.connect("activate", self.trayicon_activate)

    def right_click_event(self, icon, button, tm):
        menu = Gtk.Menu()

        new_tweet = Gtk.MenuItem()
        new_tweet.set_label(_("New Tweet"))
        new_tweet.connect("activate", self.on_new_tweet)
        menu.append(new_tweet)

        quit_item = Gtk.MenuItem()
        quit_item.set_label(_("Quit"))
        quit_item.connect("activate", self.on_exit)
        menu.append(quit_item)

        menu.show_all()

        menu.popup(None, None,
                   lambda w, x: self.statusicon.position_menu(
                   menu, self.statusicon),
                   self.statusicon, 3, tm)

    def trayicon_activate (self, widget, data = None):
        """Toggle status icon"""
        self.emit_signal("toggle-window-visibility")

    def on_new_tweet(self, widget):
        self.emit_signal_with_arg("new-tweet-compose", None)

    def on_exit(self, widget):
        self.emit_signal_with_args("on-exit", (None, None, None))

