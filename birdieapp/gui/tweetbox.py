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

from gi.repository import Gtk, Gdk, Pango, GObject
from birdieapp.constants import BIRDIE_SHARE_PATH
from birdieapp.utils.timecalc import pretty_time, twitter_date_to_datetime
from birdieapp.gui.dialogs import confirm_dialog
from birdieapp.gui.mediaviewer import MediaViewer
from birdieapp.signalobject import SignalObject
import birdieapp.utils.ttp as ttp
import gettext
import re

_ = gettext.gettext


class TweetBox(Gtk.EventBox, SignalObject):
    __gtype_name__ = "TweetBox"

    def __init__(self, data, active_account):
        super(TweetBox, self).__init__()
        super(TweetBox, self).init_signals()

        self.data = data
        self.active_account = active_account
        self.set_context()
        self.parser = ttp.Parser()

        # revealer - for animations
        self.revealer = Gtk.Revealer()
        self.revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN)
        self.revealer.set_transition_duration(1000)
        self.revealer.set_reveal_child(False)

        # tweet box - main container
        self.tweet_box = Gtk.Box(
            orientation=Gtk.Orientation.HORIZONTAL, margin=8)

        # avatar box
        self.avatar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        # details box
        self.details_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)

        self.set_avatar()

        # verified account image
        self.verified_img = Gtk.Image()
        self.verified_img.set_from_icon_name("twitter-verified",
                                             Gtk.IconSize.MENU)

        self.set_info_line()
        self.set_user_name_box()
        self.set_info_line_labels()
        self.set_tweet()
        self.set_media_box()

        # action buttons
        self.actions_revealer = Gtk.Revealer()
        self.actions_revealer.set_transition_type(Gtk.RevealerTransitionType.CROSSFADE)
        self.actions_revealer.set_transition_duration(250)
        self.actions_revealer.set_reveal_child(False)

        self.connect("enter_notify_event", lambda _, __: self.actions_revealer.set_reveal_child(True))
        self.connect("leave_notify_event", lambda _, __: self.actions_revealer.set_reveal_child(False))
        self.actions_box = Gtk.Box()
        self.actions_revealer.add(self.actions_box)

        self.set_reply()
        self.set_retweets()
        self.set_favorites()
        self.set_conversations()
        self.set_destroy_own_tweets()

        # spacer
        spacer = Gtk.Label()
        self.actions_box.pack_start(spacer, True, True, 0)

        self.set_client_info()

        # add actions
        self.details_box.pack_start(self.actions_revealer, True, True, 0)

        # actions events
        self.set_events(Gdk.EventMask.BUTTON_RELEASE_MASK)

        if not self.dm:
            self.reply_box.connect("clicked", self.on_reply)
        else:
            self.reply_box.connect("clicked", self.on_dm_reply)

        self.favorites_box.connect("clicked", self.on_favorite)
        self.media_box.connect("button-release-event", self.on_media)
        self.media_box.connect(
            "enter-notify-event", lambda x, y: self.on_mouse_enter(x, y))

        self.tweet_box.pack_start(self.details_box, True, True, 8)
        self.revealer.add(self.tweet_box)
        self.add(self.revealer)
        self.show_all()

    def set_context(self):
        # check if this is a favorite
        if 'favorited' in self.data and not self.data['favorited']:
            self.favorited = False
        else:
            self.favorited = True

        # check if this is our retweet
        if 'retweeted_by_screen_name' in self.data and \
                self.data['retweeted_by_screen_name'] == \
                self.active_account.screen_name:
            self.retweeted = True
        elif 'retweeted' in self.data and not self.data['retweeted']:
            self.retweeted = False
        else:
            self.retweeted = True

        # check if this is our own tweet:
        if 'user' in self.data \
                and self.data['user']['screen_name'] \
                == self.active_account.screen_name:
            self.own_tweet = True
        else:
            self.own_tweet = False

        # check if is an incoming direct message
        self.dm_sent = False

        if 'sender' in self.data:
            self.dm = True
            self.data['user'] = self.data['sender']
            if self.data['user']['screen_name'] == \
                    self.active_account.screen_name:
                self.dm_sent = True
            else:
                self.dm_sent = False
        else:
            self.dm = False

    def set_avatar(self):
        """Set avatar image"""
        self.avatar_img = Gtk.Image()
        self.avatar_img.set_from_file(BIRDIE_SHARE_PATH + "/default.png")
        self.avatar_img.set_halign(Gtk.Align.START)
        self.avatar_img.set_valign(Gtk.Align.START)
        self.avatar_event = Gtk.EventBox()

    def set_favorites(self):
        """ Set favorites"""
        self.favorites_box = Gtk.Button()
        self.favorites_box.set_tooltip_text(_('Favorite'))
        self.favorites_box.set_relief(Gtk.ReliefStyle.NONE)
        self.favorites_img = Gtk.Image()

        if not self.dm:
            if not self.favorited:
                self.favorites_img.set_from_icon_name("twitter-fav",
                                                      Gtk.IconSize.MENU)
            else:
                self.favorites_img.set_from_icon_name(
                    "twitter-favd", Gtk.IconSize.MENU)

            self.favorites_box.add(self.favorites_img)
            self.actions_box.pack_start(self.favorites_box, False, False, 0)

            if not self.own_tweet:
                self.favorites_box.set_margin_left(15)

            self.total_favorites = Gtk.Label()
            self.total_favorites.set_use_markup(True)
            self.total_favorites.set_selectable(False)

            if 'favorite_count' in self.data and self.data['favorite_count']:
                if not self.favorited:
                    color = "#999"
                else:
                    color = "#eba429"
                self.total_favorites.set_markup("<span color='" + color +
                                                "' font_weight='bold' \
                                                size='small'>" + str(
                                                self.data['favorite_count'])
                                                + "</span>")

            self.actions_box.pack_start(self.total_favorites, False, False, 2)

    def set_conversations(self):
        """Set conversations button"""
        if 'in_reply_to_screen_name' in self.data and 'in_reply_to_status_id' \
                in self.data and self.data['in_reply_to_screen_name']:
            self.conversations_box = Gtk.Button()
            self.conversations_box.set_tooltip_text(_('View Conversation'))
            self.conversations_box.set_relief(Gtk.ReliefStyle.NONE)
            self.conversations_img = Gtk.Image()
            self.conversations_img.set_from_icon_name("twitter-thread",
                                                      Gtk.IconSize.MENU)
            self.conversations_box.set_margin_left(15)
            self.conversations_box.add(self.conversations_img)
            self.actions_box.pack_start(self.conversations_box, False, False, 0)
            self.conversations_box.connect("clicked",
                                           self.on_view_conversation,
                                           self.data['id'])

    def set_info_line(self):
        """ Replies and retweets info line (icons)"""
        if 'in_reply_to_screen_name' in self.data and 'in_reply_to_status_id' \
                in self.data and self.data['in_reply_to_screen_name'] \
                and self.data['in_reply_to_status_id']:
            self.info_img = Gtk.Image()
            self.info_img.set_from_icon_name(
                "twitter-reply", Gtk.IconSize.MENU)
            self.info_img.set_halign(Gtk.Align.END)
            self.info_img.set_margin_bottom(6)
            self.avatar_box.pack_start(self.info_img, False, False, 0)
        elif 'retweeted_by' in self.data and 'retweeted_by' in self.data:
            self.info_img = Gtk.Image()
            self.info_img.set_from_icon_name(
                "twitter-retweet", Gtk.IconSize.MENU)
            self.info_img.set_halign(Gtk.Align.END)
            self.info_img.set_margin_bottom(6)
            self.avatar_box.pack_start(self.info_img, False, False, 0)

        self.avatar_event.add(self.avatar_img)
        self.avatar_box.pack_start(self.avatar_event, False, False, 0)
        self.tweet_box.pack_start(self.avatar_box, False, False, 4)

    def set_info_line_labels(self):
        """ Replies and retweets info line (labels)"""
        if 'in_reply_to_screen_name' in self.data and 'in_reply_to_status_id' \
                in self.data and self.data['in_reply_to_screen_name'] \
                and self.data['in_reply_to_status_id']:
            self.info_label = Gtk.Label("")
            self.info_label.set_selectable(False)
            txt = "<span color='#999' font_weight='bold' size='small'>"
            txt += _("in reply to") + "<span underline='none'>"
            txt += "<a href='birdie://user/"
            txt += self.data['in_reply_to_screen_name']
            txt += "'>" + " @" + self.data['in_reply_to_screen_name']
            txt += "</a></span></span>"
            self.info_label.set_markup(txt)
            self.info_label.set_halign(Gtk.Align.START)
            self.info_label.set_margin_bottom(6)
            self.details_box.pack_start(self.info_label, False, False, 0)
        elif 'retweeted_by' in self.data:
            self.info_label = Gtk.Label()
            txt = "<span color='#999' font_weight='bold' size='small'>"
            txt += _("retweeted by") + "<span underline='none'>"
            txt += "<a href='birdie://user/"
            txt += self.data['retweeted_by_screen_name']
            txt += "'> " + self.data['retweeted_by'] + "</a></span></span>"
            self.info_label.set_markup(txt)
            self.info_label.set_halign(Gtk.Align.START)
            self.info_label.set_margin_bottom(6)
            self.details_box.pack_start(self.info_label, False, False, 0)

        if self.data['user']['verified']:
            self.user_name_box.pack_start(self.verified_img, False, False, 0)

        self.user_name_box.pack_start(self.user_name, True, True, 0)
        self.user_name_box.pack_end(self.time, False, False, 0)
        self.details_box.pack_start(self.user_name_box, False, True, 0)

    def set_user_name_box(self):
        self.user_name_box = Gtk.Box()
        self.user_name = Gtk.Label("")
        self.user_name.set_halign(Gtk.Align.START)
        self.user_name.set_valign(Gtk.Align.START)
        self.user_name.set_selectable(False)
        self.user_name.set_ellipsize(3)
        txt = "<span underline='none' font_weight='bold'"
        txt += "size='large'>" + self.data['user']['name']
        txt += "</span> <span font_weight='light' color='#999' underline='none'>"
        txt += "<a href='birdie://user/" + self.data['user']['screen_name']
        txt += "'>@" + self.data['user']['screen_name'] + "</a></span>"
        self.user_name.set_markup(txt)
        self.time = Gtk.Label("")
        datetime = twitter_date_to_datetime(self.data['created_at'])
        self.time.set_markup("<span color='#999' size='small'>" +
                             pretty_time(datetime) + "</span>")

    def set_retweets(self):
        """ Set retweets"""
        self.retweet_box = Gtk.MenuButton()
        self.retweet_box.set_tooltip_text(_('Retweet'))
        self.retweet_box.set_relief(Gtk.ReliefStyle.NONE)
        self.retweet_img = Gtk.Image()

        if not self.retweeted:
            self.retweet_img.set_from_icon_name("twitter-retweet",
                                                Gtk.IconSize.MENU)
        else:
            self.retweet_img.set_from_icon_name(
                "twitter-retweeted", Gtk.IconSize.MENU)

        self.retweet_menu = Gtk.Menu()
        menu_item = Gtk.MenuItem()
        menu_item.set_label(_("Retweet"))
        menu_item.connect("activate", self.on_retweet)
        self.retweet_menu.append(menu_item)
        menu_item = Gtk.MenuItem()
        menu_item.set_label(_("Retweet with quote"))
        menu_item.connect("activate", self.on_retweet_quote)
        self.retweet_menu.append(menu_item)
        self.retweet_menu.show_all()
        self.retweet_box.set_popup(self.retweet_menu)

        if not self.own_tweet and not self.dm:
            self.retweet_box.set_margin_left(15)
            self.retweet_box.add(self.retweet_img)
            self.actions_box.pack_start(self.retweet_box, False, False, 0)

            self.total_retweets = Gtk.Label()
            self.total_retweets.set_use_markup(True)
            self.total_retweets.set_selectable(False)

            if 'retweet_count' in self.data and self.data['retweet_count']:
                if not self.retweeted:
                    color = "#999"
                else:
                    color = "#0bbc61"
                self.total_retweets.set_markup("<span color='" + color +
                                               "' font_weight='bold' \
                                               size='small'>" +
                                               str(self.data['retweet_count'])
                                               + "</span>")
            if self.retweeted:
                self.retweet_box.set_sensitive(False)

            self.actions_box.pack_start(self.total_retweets, False, False, 2)

    def set_tweet(self):
        """ Set tweet"""
        for url in self.data['entities']['urls']:
            self.data['text'] = self.data['text'].replace(url['url'],
                                                          url['expanded_url'])

        # parsing tweet text
        self.data['text'] = self.parser.parse(self.data['text']).html
        del self.parser

        self.tweet_status = Gtk.Label(self.data['text'].encode('utf-8'))
        self.tweet_status.set_use_markup(True)
        self.tweet_status.set_selectable(True)
        self.tweet_status.set_line_wrap(True)
        self.tweet_status.props.wrap_mode = Pango.WrapMode.WORD_CHAR
        self.tweet_status.set_alignment(0, 0.5)
        self.tweet_status.set_halign(Gtk.Align.START)
        self.tweet_status.set_valign(Gtk.Align.START)
        self.tweet_status.set_size_request(-1, -1)
        self.details_box.pack_start(self.tweet_status, False, False, 4)

    def set_client_info(self):
        """Set client info"""
        self.client = Gtk.Label()
        self.client.set_ellipsize(3)
        if 'source' in self.data and 'source':
            txt = "<span color='#999' size='small'>" + _("via") + " "
            txt += re.sub('<[^<]+?>', '', self.data['source'])
            txt += "</span>"
            self.client.set_markup(txt)
        self.client.set_halign(Gtk.Align.END)
        self.actions_box.pack_start(self.client, False, False, 0)

    def set_destroy_own_tweets(self):
        """destroy own tweets"""
        if self.own_tweet or self.dm:
            self.destroy_btn = Gtk.Button()
            self.destroy_btn.set_tooltip_text(_('Destroy Tweet'))
            self.destroy_btn.set_relief(Gtk.ReliefStyle.NONE)
            self.destroy_img = Gtk.Image()
            self.destroy_img.set_from_icon_name(
                "twitter-delete", Gtk.IconSize.MENU)
            if self.own_tweet:
                self.destroy_btn.set_margin_left(15)
            self.destroy_btn.add(self.destroy_img)
            self.actions_box.pack_start(self.destroy_btn, False, False, 0)
            if self.dm:
                self.destroy_btn.connect("clicked", self.on_dm_destroy)
            else:
                self.destroy_btn.connect("clicked", self.on_destroy)

    def set_reply(self):
        """Set reply"""
        self.reply_box = Gtk.Button()
        self.reply_box.set_tooltip_text(_('Reply'))
        self.reply_box.set_relief(Gtk.ReliefStyle.NONE)
        self.reply_img = Gtk.Image()
        self.reply_img.set_from_icon_name("twitter-reply", Gtk.IconSize.MENU)

        if not self.own_tweet and not self.dm_sent:
            self.reply_box.add(self.reply_img)
            self.actions_box.pack_start(self.reply_box, False, False, 0)

    def set_media_box(self):
        """Set media box"""
        self.media_img = Gtk.Image()
        self.media_revealer = Gtk.Revealer()
        self.media_revealer.set_transition_type(Gtk.RevealerTransitionType.SLIDE_DOWN)
        self.media_revealer.set_transition_duration(250)
        self.media_revealer.set_reveal_child(False)
        self.media_box = Gtk.EventBox()
        self.media_revealer.add(self.media_box)

        self.media_box.set_halign(Gtk.Align.START)
        self.media_box.add(self.media_img)
        self.media_box.hide()
        self.media_box.set_no_show_all(False)
        self.details_box.pack_start(self.media_revealer, False, False, 6)

    def reveal_media(self, pixbuf):
        self.media_img.set_from_pixbuf(pixbuf)
        self.media_box.set_no_show_all(False)
        self.media_box.show_all()
        self.media_revealer.set_reveal_child(True)

    # events handling
    def on_mouse_enter(self, widget, event):
        event.window.set_cursor(
            Gdk.Cursor.new_from_name(Gdk.Display.get_default(), "hand2"))

    def on_reply(self, event):
        data = dict()
        data['in_reply_to_status_id'] = self.data['id']
        data['screen_name'] = self.data['user']['screen_name']
        data['btn'] = self.reply_box
        data['user_mentions'] = self.data['entities']['user_mentions']
        self.emit_signal_with_arg("reply", data)

    def on_dm_reply(self, event):
        data = dict()
        data['in_reply_to_status_id'] = self.data['id']
        data['screen_name'] = self.data['user']['screen_name']
        data['btn'] = self.reply_box
        self.emit_signal_with_arg("dm-reply", data)

    def on_retweet(self, event):
        if confirm_dialog(self, _("Retweet"), _("Retweet to your followers?")):
            self.emit_signal_with_args("retweet", (self, self.data['id']))
            self.retweeted = not self.retweeted
        else:
            pass

    def on_retweet_quote(self, event):
        self.emit_signal_with_args("retweet-quote", (self, self.data))

    def on_favorite(self, event):
        self.emit_signal_with_args(
            "tweet-favorited", (self, self.data['id'], self.favorited))

    def on_destroy(self, event):
        response = confirm_dialog(self, _("Destroy Tweet"), _("Are you sure?"))
        if response:
            self.emit_signal_with_args(
                "tweet-destroy", (self, self.data['id']))

    def on_dm_destroy(self, event):
        response = confirm_dialog(self,
                                  _("Destroy Message"), _("Are you sure?"))
        if response:
            self.emit_signal_with_args(
                "dm-destroy", (self, self.data['id']))

    def on_media(self, widget, event):
        MediaViewer(self.data)

    # callbacks

    def on_favorite_cb(self):
        self.emit_signal_with_args("update-favorites", (self, self.data['id']))

    def on_retweet_cb(self):
        if not self.retweeted:
            self.data['retweet_count'] += 1
            self.retweet_img.set_from_icon_name(
                "twitter-retweeted", Gtk.IconSize.MENU)
            self.total_retweets.set_markup("<span color='#0bbc61' \
                                           font_weight='bold' size='small'>" +
                                           str(self.data['retweet_count']) +
                                           "</span>")
        else:
            self.data['retweet_count'] -= 1
            self.retweet_img.set_from_icon_name(
                "twitter-retweet", Gtk.IconSize.MENU)
            self.total_retweets.set_markup("<span color='#999' \
                                           font_weight='bold' size='small'>" +
                                           str(self.data['retweet_count']) +
                                           "</span>")

        if not self.data['retweet_count']:
            self.total_retweets.set_text("")

    def on_tweet_destroy_cb(self):
        self.destroy()

    def on_dm_destroy_cb(self):
        self.destroy()

    def on_view_conversation(self, _, tweet_id):
        print "conversation!" + str(tweet_id)

    # helpers

    def update_date(self):
        datetime = twitter_date_to_datetime(self.data['created_at'])
        self.time.set_markup("<span color='#999' size='small'>" +
                             pretty_time(datetime) + "</span>")
        self.time.show_all()

    def idle_update_favorites(self):
        GObject.idle_add(lambda: self.update_favorites())

    def update_favorites(self):
        if not self.favorited:
            self.data['favorite_count'] += 1
            self.favorited = True
            self.favorites_img.set_from_icon_name(
                "twitter-favd", Gtk.IconSize.MENU)
            self.total_favorites.set_markup("<span color='#eba429' \
                                            font_weight='bold' size='small'>" +
                                            str(self.data['favorite_count']) +
                                            "</span>")
        else:
            self.data['favorite_count'] -= 1
            self.favorited = False
            self.favorites_img.set_from_icon_name(
                "twitter-fav", Gtk.IconSize.MENU)
            self.total_favorites.set_markup("<span color='#999' \
                                            font_weight='bold' size='small'>" +
                                            str(self.data['favorite_count']) +
                                            "</span>")

        if not self.data['favorite_count']:
            self.total_favorites.set_text("")

    def remove_favorite(self):
        GObject.idle_add(lambda: self.destroy())     
