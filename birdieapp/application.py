#!/usr/bin/env python
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

from birdieapp.account import Account
from birdieapp.api.birdiestreamer import BirdieStreamer
from birdieapp.api.twitter import Twitter
from birdieapp.constants import APP_KEY, APP_SECRET
from birdieapp.constants import BIRDIE_LOCAL_SHARE_PATH, BIRDIE_CACHE_PATH
from birdieapp.gui.activitybox import ActivityBox
from birdieapp.gui.dialogs import error_dialog
from birdieapp.gui.mainwindow import MainWindow
from birdieapp.gui.notificationmanager import NotificationManager
from birdieapp.gui.statusicon import StatusIcon
from birdieapp.gui.tweetbox import TweetBox
from birdieapp.gui.tweetdialog import TweetDialog
from birdieapp.gui.tweetlist import TweetList
from birdieapp.settings import Settings
from birdieapp.twython import TwythonError
from birdieapp.utils.download import Download
from birdieapp.utils.files import load_pickle, load_users
from birdieapp.utils.files import write_pickle, check_required_dirs
from birdieapp.utils.network import Network
from birdieapp.utils.strings import strip_html, get_youtube_id
from gettext import gettext as _
from gi.repository import Gtk, Gio, GLib
from threading import Thread
import argparse
import base64
import gettext
import locale
import os.path
import signal
import sys
import time


app_key = base64.b64decode(APP_KEY)
app_secret = base64.b64decode(APP_SECRET)

# set locale and install gettext
locale.setlocale(locale.LC_ALL, locale.getdefaultlocale())
locale.setlocale(locale.LC_TIME, 'C')
gettext.install('birdie', unicode=1)


class Application(Gtk.Application):
    def __init__(self):
        Gtk.Application.__init__(self, application_id="org.birdieapp",
                                 flags=Gio.ApplicationFlags.
                                 HANDLES_COMMAND_LINE)

        GLib.set_application_name("Birdie")

        self.args = None
        self.window = None
        self.accounts = None
        self.active_account = None
        self.twitter = None
        self.home_stream_thread = None
        self.tweet_dialog = None
        self.last_search_txt = None
        self.users = None

        # create required directories if they do not exist
        check_required_dirs()

    def do_startup(self):
        Gtk.Application.do_startup(self)

    def do_command_line(self, args):
        '''
        Gtk.Application command line handler
        called if Gio.ApplicationFlags.HANDLES_COMMAND_LINE is set.
        must call the self.do_activate() to get the application up and running
        '''
        Gtk.Application.do_command_line(self, args)
        parser = argparse.ArgumentParser(prog='birdie')
        # add an option
        #parser.add_argument('-c', '--color', action='store_true')
        parser.add_argument('url', default=[], nargs='*')
        self.args = parser.parse_known_args(args.get_arguments()[1:])
        self.do_activate(None)

    def do_activate(self, _):
        # birdie is not activated
        if not self.window:
            # widgets
            self.home_tweet_list = TweetList()
            self.activity_list = TweetList()
            self.dm_inbox_list = TweetList()
            self.dm_outbox_list = TweetList()
            self.tweets_list = TweetList()
            self.favorites_list = TweetList()
            self.search_list = TweetList()
            self.users_list = TweetList()

            # start twitter.com availability thread
            self.network = Network()
            self.network.connect_signal("twitter-down", self.twitter_down)
            self.network.connect_signal("twitter-up", self.twitter_up)
            self.network.start()

            # start downloader thread
            self.downloader = Download()
            self.downloader.start()

            # Initialize notification manager
            self.notification = NotificationManager()

            # initialize settings
            self.settings = Settings()
            self.tweet_count = self.settings.get('tweet_count')

            # start datetime updater thread
            self.update_tl_thread = Thread(
                target=self.update_datetimes, args=(60,))
            self.update_tl_thread.daemon = True

            # initialize the top level window
            self.window = MainWindow(self.settings)
            self.window.welcome.connect_signal("account-added", lambda x, y: (
                self.save_new_account(x, y),
                self.on_initialized(x, y)
            ))
            self.add_window(self.window)

            # connect exit signal
            self.window.connect_signal("exit", self.on_exit)

            # status icon object
            if self.settings.get("use_status_icon") == "true":
                self.tray = StatusIcon()
                self.tray.connect_signal(
                    "new-tweet-compose", self.on_new_tweet_composer)
                self.tray.connect_signal(
                    "toggle-window-visibility", self.window.toggle_visibility)
                self.tray.connect_signal("on-exit", self.window.on_exit_event)

            # hide, if settings indicate that birdie should start minimized
            if self.settings.get("start_minimized") == "true":
                self.window.hide()

            # add lists to scrolled views
            self.window.home_scrolled.add(self.home_tweet_list)
            self.window.activity_scrolled.add(self.activity_list)
            self.window.dm_inbox_scrolled.add(self.dm_inbox_list)
            self.window.dm_outbox_scrolled.add(self.dm_outbox_list)
            self.window.tweets_scrolled.add(self.tweets_list)
            self.window.favorites_scrolled.add(self.favorites_list)
            self.window.search_scrolled.add(self.search_list)
            self.window.users_scrolled.add(self.users_list)

            self.window.users_box.connect_signal("follow",
                                                 self.on_follow_th)
            self.window.users_box.connect_signal("unfollow",
                                                 self.on_unfollow_th)

            # load accounts info
            self.accounts = load_pickle(BIRDIE_LOCAL_SHARE_PATH +
                                        "accounts.obj")
            self.window.add_account_menu(
                self.accounts, self.set_active_account)

            for account in self.accounts:
                if account.active:
                    self.active_account = account
                    self.on_initialized(
                        self.active_account.token, self.active_account.secret)

            # load cached users
            self.users = load_users(BIRDIE_LOCAL_SHARE_PATH + "users.obj")

            # start thread to update timedates as daemon
            self.update_tl_thread.start()

        # if birdie is already activated
        self.window.present()

        for arg in self.args.url:
            if arg:
                if "birdie://user/" in arg:
                    user = arg.replace("birdie://user/", "")
                    if "/" in user:
                        user = user.replace("/", "")
                    if "@" in user:
                        user = user.replace("@", "")
                    self.show_profile(user)
                elif "birdie://hashtag/" in arg:
                    hashtag = arg.replace("birdie://hashtag/", "")
                    if "/" in hashtag:
                        hashtag = hashtag.replace("/", "")
                    if "" in hashtag:
                        hashtag = hashtag.replace("%23", "")
                    self.on_search(None, "#" + hashtag)

    def on_initialized(self, oauth_token,
                       oauth_token_secret, connect_signals=True):
        """
        Get threaded timelines and initialize the main streamer
        :param oauth_token: str
        :param oauth_token_secret: str
        :return:
        """
        try:
            self.twitter = Twitter(oauth_token, oauth_token_secret)
        except TwythonError as e:
            error_dialog(self.window, "Twitter error", str(e))
            self.twitter = None
            self.home_stream_thread = None
            return

        self.update_account_in_file()

        if connect_signals:
            # timelines
            self.home_tweet_list.more.connect(
                "clicked", self.get_home_timeline_th)
            self.activity_list.more.connect(
                "clicked", self.get_mentions_th)
            self.dm_inbox_list.more.connect("clicked", self.get_dm_th)
            self.dm_outbox_list.more.connect("clicked", self.get_dm_th)
            self.tweets_list.more.connect(
                "clicked", self.get_tweets_th,
                self.active_account.screen_name)
            self.favorites_list.more.connect(
                "clicked", self.get_favorites_th,
                self.active_account.screen_name)
            self.search_list.more.connect("clicked", self.on_search)
            self.users_more_tweets = self.users_list.more.connect(
                "clicked", self.get_tweets_th, None, self.users_list)

            # actions
            self.window.new_tweet.connect(
                "clicked", self.on_new_tweet_composer)
            self.window.connect_signal("search", self.on_search)

        if self.twitter.authenticated_user and self.active_account:
            # set profile
            GLib.idle_add(lambda: self.window.user_box.set(self.twitter.authenticated_user,
                                                        self.active_account))

            # get a fresh home timeline, before firing up the streamer
            self.get_home_timeline_th(None)

            self.home_stream_thread = self.init_streamer(
                self.active_account.token, self.active_account.secret)

            # get mentions
            self.get_mentions_th(None)

            # get dm
            self.get_dm_th(None)
            self.get_dm_outbox_th(None)

            # get profile
            self.get_tweets_th(None, self.active_account.screen_name)
            self.get_favorites_th(None, self.active_account.screen_name)

            self.window.stack.set_visible_child_name('home')

    # ACCOUNTS
    def save_new_account(self, oauth_token, oauth_token_secret):
        """
        save a new twitter account
        :param oauth_token: string
        :param oauth_token_secret: string
        """
        for account in self.accounts:
            account.active = False

        self.active_account = Account(
            "", "", "", True, oauth_token, oauth_token_secret)
        self.accounts.append(self.active_account)
        write_pickle(BIRDIE_LOCAL_SHARE_PATH + "accounts.obj", self.accounts)
        self.clean_all_lists()

    def update_account_in_file(self):
        write_to_file = False

        # get a fresh avatar
        self.downloader.add(
            {'url': self.twitter.authenticated_user['profile_image_url_https'],
             'box': self.window.menu_btn_img, 'type': 'own'})

        if (self.twitter.authenticated_user['screen_name'] !=
                self.active_account.screen_name
                or self.twitter.authenticated_user['name']
                != self.active_account.name
                or os.path.basename(self.twitter.authenticated_user[
                                    'profile_image_url_https'])
                != self.active_account.avatar):
            self.active_account.screen_name = self.twitter.authenticated_user[
                'screen_name']
            self.active_account.name = self.twitter.authenticated_user['name']
            self.active_account.avatar = os.path.basename(
                self.twitter.authenticated_user['profile_image_url_https'])
            write_to_file = True

        if write_to_file:
            write_pickle(
                BIRDIE_LOCAL_SHARE_PATH + "accounts.obj", self.accounts)
            self.window.add_account_menu({self.active_account},
                                        self.set_active_account)

    def set_active_account(self, screen_name):
        """Change the active account"""
        for account in self.accounts:
            if account.screen_name == screen_name:
                account.active = True
                self.active_account = account
            else:
                account.active = False
        self.clean_all_lists()
        write_pickle(BIRDIE_LOCAL_SHARE_PATH + "accounts.obj", self.accounts)
        # disconnect streaming
        self.streamer.disconnect()
        self.on_initialized(
            self.active_account.token,
            self.active_account.secret, connect_signals=False)

    def clean_all_lists(self):
        self.home_tweet_list.empty()
        self.activity_list.empty()
        self.dm_inbox_list.empty()
        self.dm_outbox_list.empty()
        self.tweets_list.empty()
        self.favorites_list.empty()
        self.search_list.empty()
        self.users_list.empty()

    # STREAMER

    def init_streamer(self, oauth_token, oauth_token_secret, stream='user'):
        """
        Initializes a user streamer object
        :param oauth_token: string
        :param oauth_token_secret: string
        :param stream: string - 'user' or 'site'
        :return:
        """
        self.streamer = BirdieStreamer(base64.b64decode(APP_KEY),
                                  base64.b64decode(APP_SECRET),
                                  oauth_token, oauth_token_secret)
        self.streamer.connect_signal("tweet-received", self.on_new_tweet_received)
        self.streamer.connect_signal("event-received", self.on_event_received)
        self.streamer.connect_signal("dm-received", self.on_new_dm_received)

        try:
            stream_thread = Thread(target=getattr(self.streamer, stream))
            stream_thread.daemon = True
            stream_thread.start()
            return stream_thread
        except Thread:
            print("Error: unable to start thread")

    # HOME TIMELINE

    def get_home_timeline_th(self, _):
        try:
            th = Thread(
                target=self.get_home_timeline,
                args=(self.get_home_timeline_cb,))
            th.start()
        except Thread:
            print("Error: unable to start thread")

    def get_home_timeline(self, cb):
        try:
            if self.home_tweet_list.oldest_id > 0:
                data = self.twitter.session.get_home_timeline(
                    max_id=self.home_tweet_list.oldest_id - 1,
                    count=self.tweet_count)
            else:
                data = self.twitter.session.get_home_timeline(
                    count=self.tweet_count)
        except TwythonError as e:
            self.twitter_error(e)
            return

        index = len(data) - 1
        self.home_tweet_list.oldest_id = data[index]['id']
        cb(data)

    def get_home_timeline_cb(self, data):
        for x in range(len(data)):
            self.on_new_tweet_received(data[x], False)

    # MENTIONS

    def get_mentions_th(self, _):
        try:
            mentions_th = Thread(
                target=self.get_mentions,
                args=(self.get_mentions_cb,))
            mentions_th.start()
        except Thread:
            print("Error: unable to start thread")

    def get_mentions(self, cb):
        try:
            if self.activity_list.oldest_id > 0:
                data = self.twitter.session.get_mentions_timeline(
                    max_id=self.activity_list.oldest_id - 1,
                    count=self.tweet_count)
            else:
                data = self.twitter.session.get_mentions_timeline(
                    count=self.tweet_count)
        except TwythonError as e:
            self.twitter_error(e)
            return

        index = len(data) - 1
        self.activity_list.oldest_id = data[index]['id']
        cb(data)

    def get_mentions_cb(self, data):
        for x in range(len(data)):
            self.add_to_list(data[x], self.activity_list, False)

    # INBOX DIRECT MESSAGES

    def get_dm_th(self, _):
        try:
            dm_th = Thread(
                target=self.get_dm,
                args=(self.get_dm_cb,))
            dm_th.start()
        except Thread:
            print("Error: unable to start thread")

    def get_dm(self, cb):
        try:
            if self.dm_inbox_list.oldest_id > 0:
                data = self.twitter.session.get_direct_messages(
                    max_id=self.dm_inbox_list.oldest_id - 1,
                    count=self.tweet_count)
            else:
                data = self.twitter.session.get_direct_messages(
                    count=self.tweet_count)
        except TwythonError as e:
            self.twitter_error(e)
            return

        index = len(data) - 1
        self.dm_inbox_list.oldest_id = data[index]['id']
        cb(data)

    def get_dm_cb(self, data):
        for x in range(len(data)):
            self.add_to_list(data[x], self.dm_inbox_list, False)

    # OUTBOX DIRECT MESSAGES

    def get_dm_outbox_th(self, _):
        try:
            dm_outbox_th = Thread(
                target=self.get_dm_outbox,
                args=(self.get_dm_outbox_cb,))
            dm_outbox_th.start()
        except Thread:
            print("Error: unable to start thread")

    def get_dm_outbox(self, cb):
        try:
            if self.dm_outbox_list.oldest_id > 0:
                data = self.twitter.session.get_sent_messages(
                    max_id=self.dm_inbox_list.oldest_id - 1,
                    count=self.tweet_count)
            else:
                data = self.twitter.session.get_sent_messages(
                    count=self.tweet_count)
        except TwythonError as e:
            self.twitter_error(e)
            return

        index = len(data) - 1
        if index > 0 and index < len(data):
            self.dm_outbox_list.oldest_id = data[index]['id']
        cb(data)

    def get_dm_outbox_cb(self, data):
        for x in range(len(data)):
            self.add_to_list(data[x], self.dm_outbox_list, False)

    # OWN TWEETS

    def get_tweets_th(self, _, screen_name, list=None):
        try:
            tweets_th = Thread(
                target=self.get_tweets,
                args=(self.get_tweets_cb, screen_name, list))
            tweets_th.start()
        except Thread:
            print("Error: unable to start thread")

    def get_tweets(self, cb, screen_name, list=None):
        if list is None:
            list = self.tweets_list
        try:
            if list.oldest_id > 0:
                data = self.twitter.session.get_user_timeline(
                    screen_name=screen_name,
                    max_id=list.oldest_id - 1,
                    count=self.tweet_count)
            else:
                data = self.twitter.session.get_user_timeline(
                    screen_name=screen_name, count=self.tweet_count)
        except TwythonError as e:
            self.twitter_error(e)
            return

        index = len(data) - 1
        list.oldest_id = data[index]['id']
        cb(data, list)

    def get_tweets_cb(self, data, list=None):
        if list is None:
            list = self.tweets_list
        for x in range(len(data)):
            self.add_to_list(data[x], list, False)

    # FAVORITES

    def get_favorites_th(self, _, screen_name):
        try:
            favorites = Thread(
                target=self.get_favorites,
                args=(self.get_favorites_cb, screen_name,))
            favorites.start()
        except Thread:
            print("Error: unable to start thread")
            return None

    def get_favorites(self, cb, screen_name):
        try:
            if self.favorites_list.oldest_id > 0:
                data = self.twitter.session.get_favorites(
                    screen_name=screen_name,
                    max_id=self.favorites_list.oldest_id - 1,
                    count=self.tweet_count)
            else:
                data = self.twitter.session.get_favorites(
                    screen_name=screen_name, count=self.tweet_count)
        except TwythonError as e:
            self.twitter_error(e)
            return

        index = len(data) - 1
        self.favorites_list.oldest_id = data[index]['id']
        cb(data)

    def get_favorites_cb(self, data):
        for x in range(len(data)):
            self.add_to_list(data[x], self.favorites_list, False)

    # ACTIONS CALLBACKS

    def on_new_tweet_composer(self, _):
        if self.window.dm.get_active():
            dm = True
        else:
            dm = False
        self.tweet_dialog = TweetDialog(
            '', [], self.window, self.active_account.avatar,
            dm, None, False, self.users)
        self.tweet_dialog.connect_signal(
            "new-tweet-dispatcher", lambda x: self.on_new_tweet_dispatcher(x))
        self.tweet_dialog.connect_signal(
            "new-dm-dispatcher", lambda x: self.on_new_dm_dispatcher(x))

    def on_new_tweet_dispatcher(self, data):
        self.tweet_dialog.destroy()
        self.twitter.update_status(data)

    def on_new_dm_dispatcher(self, data):
        self.tweet_dialog.destroy()
        self.twitter.send_dm_status(data)

    def on_event_received(self, data, stream=True):
        if 'event' in data and data['event'] == 'favorite'\
                or data['event'] == 'unfavorite':

            if data['event'] == 'favorite':
                fav = _("favorited")
            else:
                fav = _("unfavorited")

            screen_name = data['source']['screen_name']

            # if own favorite, add to list and return
            if screen_name == self.active_account.screen_name:
                #print data
                if data['event'] == 'favorite':
                    data = data['target_object']
                    data['favorited'] = True
                    self.add_to_list(data, self.favorites_list, stream)
                return

            name = data['source']['name']
            profile = data['source']['profile_image_url']
            data = data['target_object']
            data['user']['name'] = name + " " + fav + " " + _("your tweet")
            data['user']['profile_image_url'] = profile
            data['user']['screen_name'] = screen_name

            self.add_to_list(data, self.activity_list, stream)

            if stream and self.settings.get("notify_events") == 'true':
                self.notification.notify(name + " " + fav + " " + _("a Tweet"),
                                         strip_html(data['text']),
                                         BIRDIE_CACHE_PATH
                                         + os.path.basename(profile))

        if 'event' in data and data['event'] == 'follow' \
                and data['source']['screen_name'] != self.active_account.screen_name:
            data['name'] = data['source']['name']
            data['screen_name'] = data['source']['screen_name']
            data['profile_image_url'] = data['source']['profile_image_url']
            self.add_to_event(data, self.activity_list, stream)
            if stream and self.settings.get("notify_events") == 'true':
                self.notification.notify(_("You've got a new follower!'"),
                                         data['source']['name'] + " "
                                         + _("is now following you on Twitter"),
                                         BIRDIE_CACHE_PATH
                                         + os.path.basename(data['source']['profile_image_url']))

    def on_new_tweet_received(self, data, stream=True):
        # add user to cache
        if self.users:
            self.users.add(data['user']['screen_name'])

        # we've got a mention
        if self.active_account.screen_name in data['text']:
            self.on_new_mention_received(data, stream)
            return

        self.add_to_list(data, self.home_tweet_list, stream)

        if stream and self.settings.get("notify_tweets") == 'true':
            self.notification.notify(_("New tweet from ") + data['user']['name'],
                                     strip_html(data['text']), BIRDIE_CACHE_PATH +
                                     os.path.basename(data['user']['profile_image_url']))

    def on_new_mention_received(self, data, stream=True):
        if stream:
            self.add_to_list(data, self.activity_list, stream)
            self.window.mentions_img.set_from_icon_name('twitter-mentions-urgent',
                                                        Gtk.IconSize.LARGE_TOOLBAR)

        if stream and self.settings.get("notify_mentions") == 'true':
            self.notification.notify(_("New mention from ")
                                     + data['user']['name'], strip_html(data['text']),
                                     BIRDIE_CACHE_PATH
                                     + os.path.basename(data['user']['profile_image_url']),
                                     urgency=2)

    def on_new_search_received(self, data, stream=True):
        self.add_to_list(data, self.search_list, stream)

    def on_new_dm_received(self, data, stream=True):
        box = TweetBox(data, self.active_account)
        box.connect_signal(
            "tweet-favorited",
            lambda x, y, z: self.on_tweet_favorited(x, y, z))
        box.connect_signal(
            "dm-destroy", lambda x, y: self.on_dm_destroy(x, y))
        box.connect_signal("reply", lambda x: self.on_reply(x))
        if data['sender']['screen_name'] == self.active_account.screen_name:
            GLib.idle_add(lambda: self.dm_outbox_list.append(box, stream))
        else:
            GLib.idle_add(lambda: self.dm_inbox_list.append(box, stream))
        self.downloader.add(
            {'url': data['sender']['profile_image_url'],
                'box': box, 'type': 'avatar'})
        try:
            for media in data['entities']['media']:
                self.downloader.add(
                    {'url': media['media_url_https'],
                        'box': box, 'type': 'media'})
        except:
            pass

        self.window.dm_img.set_from_icon_name('twitter-dm-urgent',
                                              Gtk.IconSize.LARGE_TOOLBAR)

        if stream and self.settings.get("notify_dm") == 'true':
            if data['sender']['screen_name'] != \
                    self.active_account.screen_name:
                self.notification.notify(_("New Direct Message from ")
                                         + data['user']['name'],
                                         strip_html(data['text']),
                                         BIRDIE_CACHE_PATH
                                         + os.path.basename(data['user']['profile_image_url']),
                                         urgency=2)

    def on_tweet_favorited(self, tweetbox, tweet_id, favorite):
        try:
            tweet_favorited_th = Thread(
                target=self.twitter.create_favorite(tweet_id, favorite))
            tweet_favorited_th.callback = tweetbox.on_favorite_cb()
            tweet_favorited_th.start()
        except Thread:
            print("Error: unable to start thread")

    def on_tweet_destroy(self, tweetbox, tweet_id):
        try:
            tweet_destroy_th = Thread(
                target=self.twitter.destroy_tweet(tweet_id))
            tweet_destroy_th.callback = tweetbox.on_tweet_destroy_cb()
            tweet_destroy_th.start()
        except Thread:
            print("Error: unable to start thread")

    def on_dm_destroy(self, tweetbox, dm_id):
        try:
            dm_destroy_th = Thread(
                target=self.twitter.destroy_dm(dm_id))
            dm_destroy_th.callback = tweetbox.on_dm_destroy_cb()
            dm_destroy_th.start()
        except Thread:
            print("Error: unable to start thread")

    def on_retweet(self, tweetbox, tweet_id):
        try:
            retweet_th = Thread(target=self.twitter.retweet(tweet_id))
            retweet_th.callback = tweetbox.on_retweet_cb()
            retweet_th.start()
        except Thread:
            print("Error: unable to start thread")

    def on_retweet_quote(self, tweetbox, data):
        self.tweet_dialog = TweetDialog(data['user']['screen_name'],
                                        data['text'], self.window,
                                        self.active_account.avatar,
                                        False, data['id'], quote=True)
        self.tweet_dialog.connect_signal(
            "retweet-quote-dispatcher",
            lambda x: self.on_retweet_quote_dispatcher(x))

    def on_retweet_quote_dispatcher(self, data):
        self.tweet_dialog.destroy()
        self.twitter.update_status(data)

    def on_reply(self, data):
        self.tweet_dialog = TweetDialog(data['screen_name'],
                                        data['user_mentions'], self.window,
                                        self.active_account.avatar,
                                        False, data['in_reply_to_status_id'])
        self.tweet_dialog.connect_signal(
            "new-tweet-dispatcher", lambda x: self.on_new_tweet_dispatcher(x))

    def on_dm_reply(self, data):
        self.tweet_dialog = TweetDialog(data['screen_name'],
                                        None, self.window,
                                        self.active_account.avatar,
                                        True, data['in_reply_to_status_id'])
        self.tweet_dialog.connect_signal(
            "new-dm-dispatcher", lambda x: self.on_new_dm_dispatcher(x))

    def on_search(self, _, txt=None):
        self.window.deselect_all_buttons()
        self.window.stack.set_visible_child(self.window.search_scrolled)
        self.window.searchbar.set_search_mode(False)
        if txt is None:
            txt = self.last_search_txt
        else:
            self.search_list.oldest_id = None
            self.search_list.empty()

        try:
            search_th = Thread(target=self.twitter.search,
                               args=(txt, self.search_list.oldest_id,
                                     self.on_search_cb,))
            search_th.start()
        except Thread:
            print("Error: unable to start thread")
            return None

    def on_search_cb(self, data, txt):
        if len(data['statuses']):
            data = data['statuses']

            for x in range(len(data)):
                self.on_new_search_received(data[x], False)

            index = len(data) - 1

            if index >= 0:
                self.search_list.oldest_id = data[index]['id']
                self.last_search_txt = txt
        else:
            GLib.idle_add(lambda: error_dialog(self.window,
                                               _("Searching"),
                                               _("No more results.")))

    # FOLLOW

    def on_follow_th(self, screen_name):
        try:
            th = Thread(target=self.on_follow, args=(screen_name,))
            th.callback = self.on_follow_cb()
            th.start()
        except Thread:
            print("Error: unable to start follow thread")

    def on_follow(self, screen_name):
        try:
            self.twitter.session.create_friendship(screen_name=screen_name)
        except TwythonError as e:
            self.twitter_error(e)

    def on_follow_cb(self):
        GLib.idle_add(lambda: self.window.users_box.toggle_follow(True))

    # UNFOLLOW

    def on_unfollow_th(self, screen_name):
        try:
            th = Thread(target=self.on_unfollow, args=(screen_name,))
            th.callback = self.on_unfollow_cb()
            th.start()
        except Thread:
            print("Error: unable to start unfollow thread")

    def on_unfollow(self, screen_name):
        try:
            self.twitter.session.destroy_friendship(screen_name=screen_name)
        except TwythonError as e:
            self.twitter_error(e)

    def on_unfollow_cb(self):
        GLib.idle_add(lambda: self.window.users_box.toggle_follow(False))


    # SHOW PROFILE

    def show_profile(self, screen_name):
        self.users_list.empty()
        self.window.deselect_all_buttons()
        self.users_list.more.disconnect(self.users_more_tweets)
        self.users_more_tweets = self.users_list.more.connect(
            "clicked", self.get_tweets_th, screen_name, self.users_list)

        try:
            th = Thread(target=self.twitter.get_user,
                        args=(screen_name, self.show_profile_cb,))
            th.start()
        except Thread:
            print("Error: unable to start thread")

    def show_profile_cb(self, data):
        self.lookup_friendships_th(data)

    # FRIENDSHIPS

    def lookup_friendships_th(self, data):
        try:
            th = Thread(target=self.lookup_friendships,
                        args=(data, self.lookup_friendships_cb,))
            th.start()
        except Thread:
            print("Error: unable to start lookup friendship thread")

    def lookup_friendships(self, data, cb):
        try:
            fs_data = self.twitter.session.lookup_friendships(
                screen_name=data['screen_name'])
        except TwythonError as e:
            self.twitter_error(e)
            return

        self.lookup_friendships_cb(data, fs_data)

    def lookup_friendships_cb(self, data, fs_data):
        GLib.idle_add(lambda: self.window.stack.set_visible_child(
            self.window.users_profile_box))
        self.window.users_box.screen_name = data['screen_name']
        GLib.idle_add(lambda: self.window.users_box.set(data,
                                                        self.active_account,
                                                        fs_data))
        self.get_tweets(self.get_tweets_cb, data['screen_name'],
                        self.users_list)

    # HELPERS

    def add_to_event(self, data, tweet_list, stream):
        box = ActivityBox(data, self.active_account)
        GLib.idle_add(lambda: tweet_list.append(box, stream))

    def add_to_list(self, data, tweet_list, stream):
        """
        Create a TweetBox and add it to the TweetList
        :param data: BirdieStreamer data obj
        :param tweet_list: TweetList obj
        :param stream: bool
        """

        # retweets
        if 'retweeted_status' in data:
            data['retweeted_status']['retweeted_by'] = data['user']['name']
            data['retweeted_status'][
                'retweeted_by_screen_name'] = data['user']['screen_name']
            data = data['retweeted_status']

        box = TweetBox(data, self.active_account)
        box.connect_signal(
            "tweet-favorited",
            lambda x, y, z: self.on_tweet_favorited(x, y, z))
        box.connect_signal(
            "tweet-destroy", lambda x, y: self.on_tweet_destroy(x, y))
        box.connect_signal(
            "dm-destroy", lambda x, y: self.on_dm_destroy(x, y))
        box.connect_signal("retweet",
                           lambda x, y: self.on_retweet(x, y))
        box.connect_signal("retweet-quote",
                           lambda x, y: self.on_retweet_quote(x, y))
        box.connect_signal("reply", lambda x: self.on_reply(x))
        box.connect_signal("dm-reply", lambda x: self.on_dm_reply(x))
        box.connect_signal("update-favorites", self.update_favorites)

        # dms
        if tweet_list == self.dm_inbox_list or \
                tweet_list == self.dm_outbox_list:
            profile_image_url = data['sender']['profile_image_url_https']
        else:
            profile_image_url = data['user']['profile_image_url']

        GLib.idle_add(lambda: tweet_list.append(box, stream))

        self.downloader.add(
            {'url': profile_image_url, 'box': box, 'type': 'avatar'})

        if tweet_list != self.dm_inbox_list and \
                tweet_list != self.dm_outbox_list:
            try:
                for media in data['entities']['media']:
                    self.downloader.add(
                        {'url': media['media_url_https'],
                            'box': box, 'type': 'media'})
            except:
                pass
        # trying to catch imgur images
        try:
            for media in data['entities']['urls']:
                if "imgur.com" in media['expanded_url']:
                    media['expanded_url'] = media['expanded_url'].replace(
                        "http://imgur.com/" +
                        os.path.basename(media['expanded_url']),
                        "http://i.imgur.com/" +
                        os.path.basename(media['expanded_url']) + '.jpg')
                    self.downloader.add(
                        {'url': media['expanded_url'],
                         'box': box, 'type': 'media'})
        except:
            pass

        # trying to catch youtube video
        try:
            for media in data['entities']['urls']:
                if "youtube.com" in media['expanded_url'] or \
                        "youtu.be" in media['expanded_url']:
                    if "youtu.be" in media['expanded_url']:
                        media['expanded_url'] = \
                            media['expanded_url'].replace("youtu.be/",
                                                          "youtube.com/watch?v=")
                    youtube_id = get_youtube_id(media['expanded_url'])
                    youtube_thumb = "http://i3.ytimg.com/vi/" + \
                        youtube_id + "/mqdefault.jpg"
                    self.downloader.add(
                        {'url': youtube_thumb,
                         'box': box, 'type': 'youtube', 'id': youtube_id})
        except:
            pass

    def update_datetimes(self, n):
        while True:
            GLib.idle_add(lambda: self.home_tweet_list.update_datetimes())
            GLib.idle_add(lambda: self.activity_list.update_datetimes())
            GLib.idle_add(lambda: self.dm_inbox_list.update_datetimes())
            GLib.idle_add(lambda: self.dm_outbox_list.update_datetimes())
            GLib.idle_add(lambda: self.search_list.update_datetimes())
            time.sleep(n)

    def update_favorites(self, box, tweet_id):
        self.home_tweet_list.update_favorites(box, tweet_id)
        self.activity_list.update_favorites(box, tweet_id)
        self.tweets_list.update_favorites(box, tweet_id)
        self.search_list.update_favorites(box, tweet_id)
        self.users_list.update_favorites(box, tweet_id)
        self.favorites_list.remove_favorite(box, tweet_id)

    def twitter_down(self):
        self.window.twitter_down()

    def twitter_up(self):
        self.window.twitter_up()

    def twitter_error(self, e):
        GLib.idle_add(lambda: error_dialog(self.window,
                      "Twitter error", e.message))

    def on_exit(self):
        self.window.store_geometry()
        self.settings.save()
        write_pickle(BIRDIE_LOCAL_SHARE_PATH + "users.obj", self.users)
        self.window.destroy()
