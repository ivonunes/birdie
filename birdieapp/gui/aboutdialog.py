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
from birdieapp.constants import APP_NAME, APP_VERSION, APP_URL


class AboutDialog(Gtk.AboutDialog):

    """Build the about dialog"""
    __gtype_name__ = "AboutDialog"

    def __init__(self, widget):
        super(AboutDialog, self).__init__()

        self.set_destroy_with_parent(True)
        self.set_modal(True)
        self.set_program_name(APP_NAME)
        self.set_comments(_("Twitter client for Linux"))
        self.set_version(APP_VERSION)
        self.set_artists(["Daniel Foré", "Mustapha Asbbar"])
        self.set_authors(["Ivo Nunes", "Vasco Nunes"])
        self.set_copyright("Copyright © 2013-2014 Ivo Nunes / Vasco Nunes")
        self.set_license_type(Gtk.License.GPL_3_0)
        self.set_website_label(_("Birdie Website"))
        self.set_wrap_license(True)
        self.set_logo_icon_name("birdie")
        self.set_website(APP_URL)
        self.set_transient_for(widget.get_toplevel())
        self.run()
        self.destroy()
