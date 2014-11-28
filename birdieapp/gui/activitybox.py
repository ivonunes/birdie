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
from birdieapp.constants import BIRDIE_SHARE_PATH
from birdieapp.utils.timecalc import pretty_time, twitter_date_to_datetime
import gettext

_ = gettext.gettext


class ActivityBox(Gtk.EventBox):
    __gtype_name__ = "ActivityBox"

    def __init__(self, data, active_account):
        super(ActivityBox, self).__init__()

        self.data = data
        self.active_account = active_account

        # tweet box - main container
        self.tweet_box = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL, margin=8)

        # avatar box
        self.avatar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        # details box
        self.details_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        # avatar image
        self.avatar_img = Gtk.Image()
        self.avatar_img.set_from_file(BIRDIE_SHARE_PATH + "/default.png")
        self.avatar_img.set_halign(Gtk.Align.START)
        self.avatar_img.set_valign(Gtk.Align.START)
        self.avatar_event = Gtk.EventBox()

        self.info_img = Gtk.Image()
        self.info_img.set_from_icon_name(
            "twitter-reply", Gtk.IconSize.MENU)
        self.info_img.set_halign(Gtk.Align.END)
        self.info_img.set_margin_bottom(6)
        self.avatar_box.pack_start(self.info_img, False, False, 0)

        self.avatar_event.add(self.avatar_img)
        self.avatar_box.pack_start(self.avatar_event, False, False, 0)
        self.tweet_box.pack_start(self.avatar_box, False, False, 4)

        # username box

        self.user_name_box = Gtk.Box()
        self.user_name = Gtk.Label("")
        self.user_name.set_halign(Gtk.Align.START)
        self.user_name.set_valign(Gtk.Align.START)
        self.user_name.set_selectable(False)
        self.user_name.set_ellipsize(True)
        txt = "<span underline='none' font_weight='bold' size='large'>"
        txt += data['name'] + " " + _("is now following you")
        txt += "</span> <span font_weight='light' color='#999'>@"
        txt += data['screen_name'] + "</span>"
        self.user_name.set_markup(txt)
        self.time = Gtk.Label("")
        datetime = twitter_date_to_datetime(data['created_at'])
        self.time.set_markup("<span color='#999' size='small'>" +
                             pretty_time(datetime) + "</span>")

        self.user_name_box.pack_start(self.user_name, True, True, 0)
        self.user_name_box.pack_end(self.time, False, False, 0)
        self.details_box.pack_start(self.user_name_box, False, True, 0)

        self.tweet_box.pack_start(self.details_box, True, True, 8)
        self.add(self.tweet_box)
        self.show_all()

    # helpers

    def update_date(self):
        datetime = twitter_date_to_datetime(self.data['created_at'])
        self.time.set_markup("<span color='#999' size='small'>" +
                             pretty_time(datetime) + "</span>")
        self.time.show_all()
