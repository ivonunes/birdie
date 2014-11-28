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

from birdieapp.constants import BIRDIE_SHARE_PATH, BIRDIE_CACHE_PATH
from birdieapp.signalobject import SignalObject
from gi.repository import Gtk, Gdk
import gettext
import os.path
from gettext import gettext as _


class UserBox(Gtk.EventBox, SignalObject):
    __gtype_name__ = "UserBox"

    def __init__(self):
        super(UserBox, self).__init__()
        super(UserBox, self).init_signals()

        self.following = False
        self.follower = False
        self.blocked = False
        self.screen_name = None

        # tweet box - main container
        self.user_box = Gtk.Box(
            orientation=Gtk.Orientation.VERTICAL, margin=0)

        # avatar image
        self.avatar_img = Gtk.Image()
        self.avatar_img.set_from_file(BIRDIE_SHARE_PATH + "/default.png")
        self.avatar_img.set_halign(Gtk.Align.CENTER)
        self.avatar_img.set_valign(Gtk.Align.START)

         # verified account image
        self.verified_img = Gtk.Image()
        self.verified_img.set_from_icon_name("twitter-verified",
                                             Gtk.IconSize.MENU)

        self.spacer = Gtk.Label("")

        # name
        self.name_label = Gtk.Label()
        self.user_name_label = Gtk.Label()
        self.local_label = Gtk.Label()

        self.user_box.pack_start(self.spacer, False, False, 0)
        self.user_box.pack_start(self.avatar_img, False, False, 0)
        self.user_box.pack_start(self.verified_img, False, False, 0)
        self.user_box.pack_start(self.name_label, False, False, 0)
        self.user_box.pack_start(self.user_name_label, False, False, 0)
        self.user_box.pack_start(self.local_label, False, False, 0)

        # details
        self.details_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL,
                                   margin=12)

        self.tweets_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                                  margin=8)
        self.tweets_box.set_halign(Gtk.Align.CENTER)
        self.tweets_label = Gtk.Label()
        self.tweets2_label = Gtk.Label()
        txt = "<span color='#000000' font_weight='bold' size='small'>"
        txt += _("TWEETS") + "</span>"
        self.tweets2_label.set_markup(txt)
        self.tweets_box.pack_start(self.tweets_label, False, False, 0)
        self.tweets_box.pack_start(self.tweets2_label, False, False, 0)
        self.details_box.pack_start(self.tweets_box, False, False, 0)

        self.follow_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                                  margin=8)
        self.follow_box.set_halign(Gtk.Align.CENTER)
        self.follow_label = Gtk.Label()
        self.follow2_label = Gtk.Label()
        txt = "<span color='#000000' font_weight='bold' size='small'>"
        txt += _("FOLLOWING") + "</span>"
        self.follow2_label.set_markup(txt)
        self.follow_box.pack_start(self.follow_label, False, False, 0)
        self.follow_box.pack_start(self.follow2_label, False, False, 0)
        self.details_box.pack_start(self.follow_box, False, False, 0)

        self.followers_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL,
                                     margin=8)
        self.followers_box.set_halign(Gtk.Align.CENTER)
        self.followers_label = Gtk.Label()
        self.followers2_label = Gtk.Label()
        txt = "<span color='#000000' font_weight='bold' size='small'>"
        txt += _("FOLLOWERS") + "</span>"
        self.followers2_label.set_markup(txt)
        self.followers_box.pack_start(self.followers_label, False, False, 0)
        self.followers_box.pack_start(self.followers2_label, False, False, 0)
        self.details_box.pack_start(self.followers_box, False, False, 0)

        self.actions_box = Gtk.MenuButton()
        self.actions_box.set_tooltip_text(_('More Options'))
        self.actions_box.set_relief(Gtk.ReliefStyle.NONE)
        self.actions_box.set_margin_top(11)
        self.actions_box.set_margin_bottom(11)
        self.actions_box.set_margin_right(2)
        self.actions_img = Gtk.Image()
        self.actions_img.set_from_icon_name("view-more-symbolic",
                                            Gtk.IconSize.MENU)
        self.actions_box.add(self.actions_img)
        self.details_box.pack_start(self.actions_box, False, False, 0)

        # actions menu
        self.actions_menu = Gtk.Menu()
        menu_item = Gtk.MenuItem()
        menu_item.set_label(_("Send Message"))
        menu_item.connect("activate", self.on_dm)
        self.actions_menu.append(menu_item)
        menu_item = Gtk.MenuItem()
        menu_item.set_label(_("Add/Remove from Lists"))
        menu_item.connect("activate", self.on_add_remove_from_lists)
        self.actions_menu.append(menu_item)
        menu_item = Gtk.MenuItem()
        menu_item.set_label(_("View profile on Twitter"))
        menu_item.connect("activate", self.on_view_profile_on_twitter)
        self.actions_menu.append(menu_item)
        menu_item = Gtk.MenuItem()
        menu_item.set_label(_("Block"))
        menu_item.connect("activate", self.on_block)
        self.actions_menu.append(menu_item)
        self.actions_menu.show_all()
        self.actions_box.set_popup(self.actions_menu)

        self.status = Gtk.Button(_("Follow"))
        self.status.set_margin_top(11)
        self.status.set_margin_bottom(11)
        self.status.get_style_context().add_class("suggested-action")
        self.details_box.pack_start(self.status, True, True, 0)

        self.user_box.pack_start(self.details_box, True, False, 0)

        self.add(self.user_box)
        self.show_all()

    def set(self, data, active_account=None, friendship_data=None):
        self.avatar_img.set_from_file(BIRDIE_CACHE_PATH
                                      + os.path.basename(
                                          data['profile_image_url']))
        txt = "<span color='#000000' font_weight='bold' size='x-large'>"
        txt += data['name'] + "</span>"
        self.name_label.set_markup(txt)
        txt = "<span color='#999' font_weight='bold'>@"
        txt += data['screen_name'] + "</span>"
        self.user_name_label.set_markup(txt)
        txt = "<span color='#999' size='small'>"
        txt += data['location'] + "</span>"
        self.local_label.set_markup(txt)
        txt = "<span color='#999' font_weight='bold' size='large'>"
        txt += str(data['statuses_count']) + "</span>"
        self.tweets_label.set_markup(txt)
        txt = "<span color='#999' font_weight='bold' size='large'>"
        txt += str(data['friends_count']) + "</span>"
        self.follow_label.set_markup(txt)
        txt = "<span color='#999' font_weight='bold' size='large'>"
        txt += str(data['followers_count']) + "</span>"
        self.followers_label.set_markup(txt)

        try:
            self.status.disconnect(self.follow_signal)
        except:
            pass

        self.follow_signal = self.status.connect("clicked",
                                         self.on_follow,
                                         data['screen_name'])

        if data['following']:
            self.status.get_style_context().remove_class("suggested-action")
            self.status.get_style_context().add_class("destructive-action")
            self.status.set_label("Unfollow")
        else:
            self.status.get_style_context().remove_class("destructive-action")
            self.status.get_style_context().add_class("suggested-action")
            self.status.set_label("Follow")

        # is our own profile?
        if data['screen_name'] == active_account.screen_name:
            self.status.set_label(_("Edit"))
            try:
                self.status.disconnect(self.follow_signal)
            except:
                pass

            self.follow_signal = self.status.connect("clicked", self.on_edit)

        # are we following this user?
        if friendship_data:
            for user in friendship_data:
                if 'following' in user['connections']:
                    self.toggle_follow(True)
                else:
                    self.toggle_follow(False)

        self.show_all()

        if not data['verified']:
            self.verified_img.hide()

    def toggle_follow(self, following=False):
        if following:
            self.status.set_label(_("Unfollow"))
            self.status.get_style_context().remove_class("suggested-action")
            self.status.get_style_context().add_class("destructive-action")
        else:
            self.status.set_label(_("Follow"))
            self.status.get_style_context().remove_class("destructive-action")
            self.status.get_style_context().add_class("suggested-action")

        self.following = following

    def on_follow(self, _, screen_name):
        if self.following:
            self.emit_signal_with_arg("unfollow", screen_name)
        else:
            self.emit_signal_with_arg("follow", screen_name)

    def on_dm(self, _):
        print "dm"

    def on_add_remove_from_lists(self, _):
        print "add/remove from lists"

    def on_view_profile_on_twitter(self, _):
        Gtk.show_uri(None, 'http://www.twitter.com/' + self.screen_name,
                     Gdk.CURRENT_TIME)

    def on_block(self, _):
        print "Block!"

    def on_edit(self, _):
        Gtk.show_uri(None, 'https://twitter.com/settings/account',
                     Gdk.CURRENT_TIME)