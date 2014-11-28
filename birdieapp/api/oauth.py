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


class OAuth():

    """OAuth object"""
    __gtype_name__ = "OAuth"

    oauth_token = None
    oauth_token_secret = None

    def __init__(self):
        self.auth = Twython(
            base64.b64decode(APP_KEY), base64.b64decode(APP_SECRET))
        self.auth = self.auth.get_authentication_tokens()
        self.oauth_token = self.auth['oauth_token']
        self.oauth_token_secret = self.auth['oauth_token_secret']

    def get_oauth_url(self):
        return self.auth['auth_url']

    def get_tokens(self, pin):
        self.twitter = Twython(
            base64.b64decode(APP_KEY), base64.b64decode(
                APP_SECRET), self.oauth_token,
            self.oauth_token_secret)
        try:
            __authorized_tokens = self.twitter.get_authorized_tokens(pin)
            self.oauth_token = __authorized_tokens['oauth_token']
            self.oauth_token_secret = __authorized_tokens['oauth_token_secret']
            return True
        except TwythonError as e:
            print(e)
            return False
