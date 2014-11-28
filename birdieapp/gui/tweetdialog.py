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

from gi.repository import Gtk, GtkSource, GdkPixbuf
from birdieapp.gui.dialogs import file_chooser
from birdieapp.signalobject import SignalObject
from birdieapp.constants import TWEET_MAX_LENGHT, BIRDIE_CACHE_PATH
from birdieapp.utils.strings import strip_html
import birdieapp.utils.ttp as ttp
import gettext

_ = gettext.gettext


class TweetDialog(Gtk.Dialog, SignalObject):
    __gtype_name__ = "TweetDialog"

    def __init__(self, screen_name, user_mentions, widget,
                 profile_image_file, dm=False, tweet_id=None,
                 quote=False, user_store=None):
        """
        Make a dialog for new tweets
        :param screen_name: string
        :param mentioned_users: list
        :param widget: Gtk.Widget
        :param profile_image_file: string
        :param dm: bool
        """
        super(TweetDialog, self).__init__()
        super(TweetDialog, self).init_signals()

        self.parser = ttp.Parser()
        self.screen_name = screen_name
        self.user_mentions = user_mentions
        self.dm = dm
        self.id = tweet_id
        self.profile_image_file = profile_image_file
        self.quote = quote
        self.users = user_store

        self.count_remaining = TWEET_MAX_LENGHT
        self.media_path = None

        self.buffer = GtkSource.Buffer()
        self.tweet_area = GtkSource.View.new_with_buffer(self.buffer)
        self.tweet_area.set_accepts_tab(False)
        lang_manager = GtkSource.LanguageManager()
        self.buffer.set_language(lang_manager.get_language('birdie'))
        self.counter_label = Gtk.Label()
        self.media_button = Gtk.Button()
        self.dm_recip = Gtk.Entry()
        self.cancel_button = Gtk.Button(_("Cancel"))
        self.tweet_button = Gtk.Button(_("Tweet") if not dm else _("Send"))

        # set dialog title according to context
        self.set_title(_("New Tweet")) if not dm else self.set_title(
            _("New Message"))

        self.set_transient_for(widget.get_toplevel())
        self.set_modal(True)
        self.set_resizable(False)
        self.set_size_request(80, 250)

        self.content_container = self.get_content_area()
        self.action_container = self.get_action_area()

        self.top_box = Gtk.Box()

        # avatar
        self.avatar_image = Gtk.Image.new_from_file(
            BIRDIE_CACHE_PATH + self.profile_image_file)
        self.avatar_image.set_valign(Gtk.Align.START)
        self.top_box.pack_start(self.avatar_image, False, False, 8)

        # tweet area
        self.tweet_area.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.top_box.pack_start(self.tweet_area, True, True, 8)

        if self.dm:
            self.dm_recip.set_text("@" + self.screen_name)
            self.content_container.pack_start(self.dm_recip, False, False, 0)

        self.content_container.pack_start(self.top_box, True, True, 8)

        # counter
        self.counter_label.set_text(str(self.count_remaining))
        self.counter_label.set_markup(
            "<span color='#777777'>" + str(self.count_remaining) + "</span>")
        self.counter_label.set_halign(Gtk.Align.START)
        self.counter_label.set_valign(Gtk.Align.CENTER)
        self.action_container.pack_start(self.counter_label, False, False, 0)

        # dummy spacer
        self.action_container.pack_start(Gtk.Label(""), True, True, 0)

        # action buttons
        self.media_button.set_tooltip_text(_("Add a Picture"))
        self.media_button.set_image(
            Gtk.Image.new_from_icon_name("insert-image-symbolic",
                                         Gtk.IconSize.MENU))
        self.media_button.set_relief(Gtk.ReliefStyle.NONE)

        self.tweet_button.get_style_context().add_class("suggested-action")
        self.tweet_button.set_sensitive(False)
        self.action_container.pack_start(self.media_button, False, False, 0)
        self.action_container.pack_start(self.cancel_button, False, False, 0)
        self.action_container.pack_start(self.tweet_button, False, False, 0)

        # events
        self.buffer.connect("changed", self.on_buffer_changed)
        self.media_button.connect("clicked", self.on_media_insert)
        self.cancel_button.connect("clicked", self.on_cancel)
        self.tweet_button.connect("clicked", self.on_tweet)

        self.set_context()

        self.show_all()

    def set_context(self):
        # dm
        if self.dm and self.screen_name == "":
            self.set_title(_("New Direct Message"))
            self.on_buffer_changed(None)
        elif self.dm:
            self.set_title(_("New Direct Message in reply to @") + self.screen_name)
        # reply
        if self.id and not self.dm and not self.quote:
            self.set_title(_("In reply to @") + self.screen_name)
            mentions = "@" + self.screen_name + " "
            if self.user_mentions:
                for user in self.user_mentions:
                    mentions += "@" + user['screen_name'] + " "
            self.buffer.set_text(mentions)
            self.on_buffer_changed(None)
        if self.quote:
            self.set_title(_("Retweet"))
            self.buffer.set_text("@" + self.screen_name
                                 + ' "'
                                 + strip_html(self.user_mentions)
                                 + '" ')
            self.on_buffer_changed(None)

    # signal events handling

    def on_media_insert(self, widget):
        response = file_chooser(_("Select a Picture"))
        if response:
            self.media_path = response
            img = Gtk.Image.new_from_pixbuf(
                GdkPixbuf.Pixbuf.new_from_file_at_scale(response,
                                                        32, 32, True))
            self.media_button.set_image(img)
            self.on_buffer_changed(None)
        else:
            self.media_path = None

    def on_cancel(self, widget):
        self.destroy()

    def on_tweet(self, widget):
        data = dict()
        data['status'] = self.buffer.get_text(
            self.buffer.get_start_iter(), self.buffer.get_end_iter(), False)
        data['in_reply_to_status_id'] = self.id
        data['media_path'] = self.media_path
        data['screen_name'] = self.screen_name
        if not self.dm and not self.quote:
            self.emit_signal_with_arg("new-tweet-dispatcher", data)
        elif self.quote:
            data['in_reply_to_status_id'] = None
            self.emit_signal_with_arg("retweet-quote-dispatcher", data)
        else:
            data['screen_name'] = self.dm_recip.get_text().replace("@", "")
            self.emit_signal_with_arg("new-dm-dispatcher", data)

    def on_buffer_changed(self, widget):
        start = self.buffer.get_start_iter()
        end = self.buffer.get_end_iter()
        filler = "0123456789012345678901"
        virtual_text = self.buffer.get_text(start, end, False)
        count = self.count_remaining - len(virtual_text)

        # compute url links
        urls = self.parser.parse(virtual_text).urls

        if urls:
            for url in urls:
                virtual_text = virtual_text.replace(url, filler)
                count = self.count_remaining - len(virtual_text)

        # compute media links
        if self.media_path:
            count -= len(filler)

        self.counter_label.set_markup(
            "<span color='#777777'>" + str(count) + "</span>")

        if ((count < 0 or count > TWEET_MAX_LENGHT)
            or (len(self.buffer.get_text(start, end, False)) < 3
                and self.dm and self.tweet_area.get_visible())):
            # make remaining chars indicator red to warn user
            if count < 0:
                self.counter_label.set_markup(
                    "<span color='#FF0000'>" + str(count) + "</span>")
            self.tweet_button.set_sensitive(False)
        else:
            self.tweet_button.set_sensitive(True)
