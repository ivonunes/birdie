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


from birdieapp.twython.streaming import TwythonStreamer
from birdieapp.signalobject import SignalObject


class BirdieStreamer(TwythonStreamer, SignalObject):

    """Streamer object"""
    __gtype_name__ = "BirdieStreamer"

    def __init__(self, app_key, app_secret, oauth_token, oauth_token_secret):
        super(BirdieStreamer, self).__init__(
            app_key, app_secret, oauth_token, oauth_token_secret)
        super(BirdieStreamer, self).init_signals()

    def on_success(self, data):
        if "event" in data:
            self.emit_signal_with_arg("event-received", data)
        if "text" in data:
            self.emit_signal_with_arg("tweet-received", data)
        elif "direct_message" in data:
            self.emit_signal_with_arg("dm-received", data['direct_message'])

    def on_error(self, status_code, data):
        print(status_code)
