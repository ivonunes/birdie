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


from birdieapp.signalobject import SignalObject
import urllib2
import threading
import time


class Network(threading.Thread, SignalObject):

    """Check for twitter.com availability"""
    __gtype_name__ = "Network"

    def __init__(self):
        super(Network, self).__init__()
        super(Network, self).init_signals()

        self.daemon = True

    def run(self):
        while True:
            try:
                urllib2.urlopen("http://www.twitter.com")
            except urllib2.URLError:
                self.emit_signal("twitter-down")
            else:
                self.emit_signal("twitter-up")
            time.sleep(10)
