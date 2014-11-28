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

from gi.repository import Gtk, GObject
from birdieapp.signalobject import SignalObject
from birdieapp.gui.tweetbox import TweetBox
import gettext

_ = gettext.gettext


class TweetList(Gtk.ListBox, SignalObject):
    __gtype_name__ = "TweetList"

    def __init__(self):
        super(TweetList, self).__init__()
        super(TweetList, self).init_signals()

        self.oldest_id = 0

        self.more = Gtk.Button()
        self.more.set_relief(Gtk.ReliefStyle.NONE)
        self.more_icon = Gtk.Image()
        self.more.set_tooltip_text(_("Show older tweets"))
        self.more_icon.set_from_icon_name("add", Gtk.IconSize.MENU)
        self.more.add(self.more_icon)
        self.prepend(self.more)

        self.set_selection_mode(Gtk.SelectionMode.NONE)
        self.show_all()

    def append(self, box, stream):
        if self.oldest_id > 0 and not stream:
            self.insert(box, len(self.get_children()) - 1)
            self.insert(
                Gtk.Separator.new(orientation=Gtk.Orientation.HORIZONTAL),
                len(self.get_children()) - 1)
            GObject.idle_add(lambda: self.show_all())
            box.revealer.set_transition_duration(250)
            GObject.idle_add(lambda: box.revealer.set_reveal_child(True))
        else:
            self.prepend(
                Gtk.Separator.new(orientation=Gtk.Orientation.HORIZONTAL))
            self.prepend(box)
            GObject.idle_add(lambda: self.show_all())
            GObject.idle_add(lambda: box.revealer.set_reveal_child(True))

    def empty(self):
        self.oldest_id = 0
        for x in self.get_children():
            if x.get_child() is not self.more:
                x.destroy()

    def update_datetimes(self):
        for row in self.get_children():
            try:
                box = row.get_child()
                box.update_date()
            except:
                pass

    def update_favorites(self, tweetbox, tweet_id):
        for x in self.get_children():
            w = x.get_child()

            if callable(getattr(w, "update_favorites", None)):
                if w.data['id'] == tweet_id:
                    w.idle_update_favorites()

    def remove_favorite(self, tweetbox, tweet_id):
        for x in self.get_children():
            w = x.get_child()

            if callable(getattr(w, "remove_favorite", None)):
                if w.data['id'] == tweet_id:
                    w.remove_favorite()