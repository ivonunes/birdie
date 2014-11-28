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


from birdieapp.api.oauth import OAuth
from birdieapp.gui.dialogs import error_dialog
from birdieapp.signalobject import SignalObject
from birdieapp.gui.dialogs import get_input
from gi.repository import Gtk
import gettext
import webbrowser

_ = gettext.gettext


class Welcome(Gtk.Box, SignalObject):

    """Build the welcome box"""
    __gtype_name__ = "Welcome"

    def __init__(self):
        super(Welcome, self).__init__()
        super(Welcome, self).init_signals()

        self.set_orientation(orientation=Gtk.Orientation.VERTICAL)

        welcome_label = Gtk.Label("")
        welcome_label.set_markup("<span font_weight='bold' size='x-large'>" +
                                 _("Welcome to Birdie") + "</span>")

        signin = Gtk.Button()
        signin.set_label(_("Add an existing Twitter account."))

        signup = Gtk.Button()
        signup.set_label(_("Create a new Twitter account."))

        self.set_valign(Gtk.Align.CENTER)
        self.set_halign(Gtk.Align.CENTER)
        self.set_vexpand(True)

        self.pack_start(welcome_label, False, False, 12)
        self.pack_start(signin, False, False, 6)
        self.pack_start(signup, False, False, 6)

        self.show_all()

        signin.connect("clicked", self.on_signin)
        signup.connect("clicked", self.on_signup)

    # events handling

    # def connect_signin (self, cb):
    #    self.cb = cb

    def on_signin(self, widget):
        """

        :param widget:
        """
        auth = OAuth()
        webbrowser.open(auth.get_oauth_url(), new=2)
        pin = get_input(widget.get_toplevel(), _("Enter PIN"))
        #
        if auth.get_tokens(pin):
            self.emit_signal_with_args(
                "account-added", (auth.oauth_token, auth.oauth_token_secret))
        else:
            error_dialog(widget.get_toplevel(), _("Error signing in"),
                         _("Invalid Twitter credentials. Please, try again."))

    @staticmethod
    def on_signup(widget):
        #new=2 opens in a new tab, if possible
        webbrowser.open('http://www.twitter.com/signup/', new=2)
