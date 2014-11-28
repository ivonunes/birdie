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


import base64
from birdieapp.twython import Twython, TwythonError
from birdieapp.constants import APP_KEY, APP_SECRET
from birdieapp.settings import Settings
import urllib


class Twitter():

    """Twitter object"""
    __gtype_name__ = "Twitter"

    def __init__(self, token, secret):
        self.session = Twython(base64.b64decode(APP_KEY),
                               base64.b64decode(APP_SECRET), token, secret)
        try:
            self.authenticated_user = self.session.verify_credentials()
        except TwythonError:
            print(TwythonError.msg)

        self.tweet_count = Settings().get('tweet_count')

    def create_favorite(self, tweet_id, favorite):
        self.session.create_favorite(id=tweet_id) if not favorite \
            else self.session.destroy_favorite(id=tweet_id)

    def destroy_tweet(self, tweet_id):
        self.session.destroy_status(id=tweet_id)

    def destroy_dm(self, dm_id):
        self.session.destroy_direct_message(id=dm_id)

    def retweet(self, tweet_id):
        self.session.retweet(id=tweet_id)

    def get_user(self, screen_name, cb):
        data = self.session.show_user(screen_name=screen_name)
        cb(data)

    def update_status(self, data):
        # with media, upload
        if data['media_path']:
            photo = open(data['media_path'], 'rb')
            # is a reply?
            if data['in_reply_to_status_id']:
                self.session.update_status_with_media(status=data['status'],
                                                      media=photo,
                                                      in_reply_to_status_id=
                                                      data['in_reply_to_status_id'])
            else:
                self.session.update_status_with_media(
                    status=data['status'], media=photo)
        # plain status
        else:
            # is a reply?
            if data['in_reply_to_status_id']:
                self.session.update_status(status=data['status'],
                                           in_reply_to_status_id=
                                           data['in_reply_to_status_id'])
            else:
                self.session.update_status(status=data['status'])

    def send_dm_status(self, data):
        self.session.send_direct_message(text=data['status'],
                                         screen_name=data['screen_name'])

    def search(self, txt, oldest_id, cb):
        try:
            query = urllib.unquote(txt).encode("utf8")
            if oldest_id > 0:
                data = self.session.search(q=query,
                                           #result_type="recent",
                                           count=self.tweet_count,
                                           max_id=oldest_id - 1)
            else:
                data = self.session.search(q=query,
                                           #result_type="recent",
                                           count=self.tweet_count)
        except TwythonError as e:
            print(e)
            return None

        cb(data, txt)
