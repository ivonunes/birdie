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

import os
import urllib
import threading
import Image, ImageDraw
from Queue import Queue
from gi.repository import GLib
from birdieapp.utils.media import cropped_thumbnail, simple_resize
from birdieapp.utils.strings import get_youtube_id
from birdieapp.constants import BIRDIE_CACHE_PATH


class Download(threading.Thread):
    __gtype_name__ = "Downloader"

    def __init__(self):
        """A class for queueing downloads in background"""

        super(Download, self).__init__()

        self.queue = Queue()
        self.daemon = True
        self.destfolder = BIRDIE_CACHE_PATH

    def run(self):
        while True:
            obj = self.queue.get()

            if not os.path.exists(self.destfolder
                                  + os.path.basename(obj['url'])):
                try:
                    self.download_url(obj['url'].replace('_normal.', '_bigger.'))
                except Exception, e:
                    print "Error: %s" % e
                self.queue.task_done()

                if obj['type'] != 'media' and obj['type'] != 'youtube':
                    def add_corners(im, rad):
                        circle = Image.new('L', (rad * 2, rad * 2), 0)
                        draw = ImageDraw.Draw(circle)
                        draw.ellipse((0, 0, rad * 2, rad * 2), fill=255)
                        alpha = Image.new('L', im.size, 255)
                        w, h = im.size
                        alpha.paste(circle.crop((0, 0, rad, rad)), (0, 0))
                        alpha.paste(circle.crop((0, rad, rad, rad * 2)), (0, h - rad))
                        alpha.paste(circle.crop((rad, 0, rad * 2, rad)), (w - rad, 0))
                        alpha.paste(circle.crop((rad, rad, rad * 2, rad * 2)), (w - rad, h - rad))
                        im.putalpha(alpha)
                        im = im.resize((48,48), Image.ANTIALIAS)
                        return im

                    im = Image.open(self.destfolder + os.path.basename(obj['url']).replace('_normal.', '_bigger.'))
                    im = add_corners(im, 10)
                    im.save(self.destfolder + os.path.basename(obj['url']) + '.png')   
                    try:
                        os.remove(self.destfolder + os.path.basename(obj['url']).replace('_normal.', '_bigger.'))
                        os.rename(self.destfolder + os.path.basename(obj['url']) + '.png', self.destfolder + os.path.basename(obj['url']))
                    except:
                        pass

            if obj['type'] == 'avatar':
                self.update_avatar(os.path.basename(obj['url']), obj['box'])
            elif obj['type'] == 'media':
                self.update_media(os.path.basename(obj['url']), obj['box'])
            elif obj['type'] == 'youtube':
                os.rename(self.destfolder + os.path.basename(obj['url']),
                          self.destfolder + obj['id'] + ".jpg")
                self.update_media(obj['id'] + ".jpg", obj['box'])
            elif obj['type'] == 'user':
                self.update_user_avatar(
                    os.path.basename(obj['url']), obj['box'])
            elif obj['type'] == 'own':
                self.update_menu_btn_avatar(
                    os.path.basename(obj['url']), obj['box'])
            else:
                pass

    def add(self, obj):
        """Enqueue a new object - a dict with 'url',
        'tweetbox' and 'type' (avatar, media, user)"""
        self.queue.put(obj)

    def download_url(self, url):
        name = url.split('/')[-1]
        dest = os.path.join(self.destfolder, name)
        urllib.urlretrieve(url, dest)

    def update_avatar(self, basefile, box):
        """update avatar in tweetbox for timelines"""
        GLib.idle_add(
            lambda: box.avatar_img.set_from_file(self.destfolder + basefile))

    def update_media(self, basefile, box):
        """update media thumbnails in tweetbox for timelines"""
        media_pixbuf = cropped_thumbnail(self.destfolder + basefile)
        GLib.idle_add(lambda: box.reveal_media(media_pixbuf))

    def update_user_avatar(self, basefile, box):
        """update avatar in userbox"""
        pass

    def update_menu_btn_avatar(self, basefile, box):
        GLib.idle_add(lambda: box.set_from_file(
            simple_resize(self.destfolder + basefile, 20, 20)))
