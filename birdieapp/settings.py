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


from ConfigParser import SafeConfigParser
from birdieapp.constants import BIRDIE_LOCAL_SHARE_PATH


class Settings(object):

    """Build the main window"""
    __gtype_name__ = "Settings"

    def __init__(self):
        super(Settings, self).__init__()

        self.settings = SafeConfigParser()
        self.settings.read(BIRDIE_LOCAL_SHARE_PATH + 'birdie.ini')
        self.test_integrity()

    def open_config(self):
        try:
            self.config_file = open(BIRDIE_LOCAL_SHARE_PATH +
                                    'birdie.ini', 'r+')
        except IOError:
            print("Unable to open config file. Creating a new one.")

    def test_integrity(self):
        if not self.settings.has_section('birdie'):
            self.write_default_config()
        else:
            self.open_config()

    def write_default_config(self):
        open(BIRDIE_LOCAL_SHARE_PATH + 'birdie.ini', 'a').close()
        self.open_config()
        self.settings.add_section('birdie')
        self.settings.set('birdie', 'dark_theme', 'false')
        self.settings.set('birdie', 'window_titlebar', 'true')
        self.settings.set('birdie', 'hide_on_close', 'true')
        self.settings.set('birdie', 'start_minimized', 'false')
        self.settings.set('birdie', 'use_status_icon', 'true')
        self.settings.set('birdie', 'notify_tweets', 'false')
        self.settings.set('birdie', 'notify_mentions', 'true')
        self.settings.set('birdie', 'notify_dm', 'true')
        self.settings.set('birdie', 'notify_events', 'true')
        self.settings.set('birdie', 'x', '0')
        self.settings.set('birdie', 'y', '0')
        self.settings.set('birdie', 'width', '480')
        self.settings.set('birdie', 'height', '400')
        self.settings.set('birdie', 'tweet_count', '20')

    def get(self, option, section="birdie"):
        return self.settings.get(section, option)

    def getint(self, option, section="birdie"):
        return int(self.settings.get(section, option))

    def getbool(self, option, section="birdie"):
        return bool(self.settings.get(section, option))

    def write(self, option, value, section="birdie"):
        self.settings.set(section, option, str(value))

    def save(self):
        self.settings.write(self.config_file)
        self.config_file.close()
