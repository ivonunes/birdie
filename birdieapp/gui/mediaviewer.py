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

from gi.repository import Gtk, Gdk, WebKit
from birdieapp.constants import BIRDIE_CACHE_PATH
from birdieapp.utils.media import fit_image_screen
from birdieapp.utils.strings import get_youtube_id

import os.path


class MediaViewer(Gtk.Window):
    __gtype_name__ = "MediaViewer"

    def __init__(self, data):
        super(MediaViewer, self).__init__()

        img = None

        self.set_resizable(False)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_events(Gdk.EventMask.KEY_PRESS_MASK)
        self.connect("key-press-event", lambda x, y: self.on_key_press(x, y))

        # image preview
        for media in data['entities']['urls']:
            if "youtube.com" in media['expanded_url'] or \
                    "youtu.be" in media['expanded_url']:
                webview = WebKit.WebView()
                self.add(webview)
                webview.load_html_string("<iframe width='640' height='390' \
                                         style='margin-left: -10px; \
                                         margin-top: -10px; \
                                         margin-bottom: -10px;' \
                                         src='http://www.youtube.com/embed/" \
                                         + get_youtube_id(media['expanded_url']) \
                                         + "?version=3&autohide=1&controls= \
                                         2&modestbranding=1&showinfo= \
                                         0&showsearch=0&vq=hd720&autoplay=1' \
                                         frameborder='0'</iframe>", \
                                         "http://www.youtube.com/embed/");
                self.set_position(Gtk.WindowPosition.CENTER_ALWAYS)
                self.show_all()
                return

        try:
            for media in data['entities']['media']:
                img = BIRDIE_CACHE_PATH + \
                    os.path.basename(media['media_url_https'])
        except:
            pass

        try:
            for media in data['entities']['urls']:
                if "imgur.com" in media['expanded_url']:
                    img = BIRDIE_CACHE_PATH + \
                        os.path.basename(media['expanded_url'])
        except:
            pass

        full_image = Gtk.Image()
        full_image.set_from_pixbuf(fit_image_screen(img, self))
        self.add(full_image)
        self.show_all()

    # events handling

    # close on space or esc keys
    def on_key_press(self, event, key):
        if key.keyval == Gdk.KEY_space or key.keyval == Gdk.KEY_Escape:
            self.destroy()
