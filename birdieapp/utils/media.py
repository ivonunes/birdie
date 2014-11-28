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


from PIL import Image, ImageDraw
from gi.repository import GdkPixbuf
from birdieapp.constants import BIRDIE_CACHE_PATH
import StringIO
import os


def resize_and_crop(img, size, crop_type='middle'):
    """
    Resize and crop an image to fit the specified size.
    """
    # Get current and desired ratio for the images
    img_ratio = img.size[0] / float(img.size[1])
    ratio = size[0] / float(size[1])
    # The image is scaled/cropped vertically or horizontally depending on the
    # ratio
    if ratio > img_ratio:
        img = img.resize(
            (size[0], size[0] * img.size[1] / img.size[0]), Image.ANTIALIAS)
        # Crop in the top, middle or bottom
        if crop_type == 'top':
            box = (0, 0, img.size[0], size[1])
        elif crop_type == 'middle':
            box = (0, (img.size[1] - size[1]) / 2, img.size[
                   0], (img.size[1] + size[1]) / 2)
        elif crop_type == 'bottom':
            box = (0, img.size[1] - size[1], img.size[0], img.size[1])
        else:
            raise ValueError('ERROR: invalid value for crop_type')
        img = img.crop(box)
    elif ratio < img_ratio:
        img = img.resize(
            (size[1] * img.size[0] / img.size[1], size[1]), Image.ANTIALIAS)
        # Crop in the top, middle or bottom
        if crop_type == 'top':
            box = (0, 0, size[0], img.size[1])
        elif crop_type == 'middle':
            box = ((img.size[0] - size[0]) / 2, 0, (
                img.size[0] + size[0]) / 2, img.size[1])
        elif crop_type == 'bottom':
            box = (img.size[0] - size[0], 0, img.size[0], img.size[1])
        else:
            raise ValueError('ERROR: invalid value for crop_type')
        img = img.crop(box)
    else:
        img = img.resize((size[0], size[1]), Image.ANTIALIAS)

    return img


def cropped_thumbnail(img):
    """Creates a centered cropped thumbnail GdkPixbuf of given image"""

    # thumbnail and crop
    try:
        im = Image.open(img)
        im = im.convert('RGBA')
        im = resize_and_crop(im, (318, 120))

        # Convert to GdkPixbuf
        buff = StringIO.StringIO()
        im.save(buff, 'ppm')
        contents = buff.getvalue()
        buff.close()
        loader = GdkPixbuf.PixbufLoader.new_with_type('pnm')
        loader.write(contents)
        pixbuf = loader.get_pixbuf()
        loader.close()
        return pixbuf
    except IOError:
        print("Invalid image file %s"%img)
        try:
            os.remove(img)
        except IOError:
            pass
        return None


def fit_image_screen(img, widget):
    pixbuf = GdkPixbuf.Pixbuf.new_from_file(img)
    screen_h = widget.get_screen().get_height()
    screen_w = widget.get_screen().get_width()

    if pixbuf.get_height() >= screen_h - 100:
        factor = float(pixbuf.get_width()) / pixbuf.get_height()
        new_width = factor * (screen_h - 100)
        pixbuf = pixbuf.scale_simple(
            new_width, screen_h - 100, GdkPixbuf.InterpType.BILINEAR)
        return pixbuf

    if pixbuf.get_width() >= screen_w:
        factor = float(pixbuf.get_height()) / pixbuf.get_width()
        new_height = factor * (screen_w - 100)
        pixbuf.scale_simple(
            screen_w - 100, new_height, GdkPixbuf.InterType.BILINEAR)
        return pixbuf

    return pixbuf

def simple_resize(img_path, w, h):
    try:
        im = Image.open(img_path)
        img = im.resize((w, h), Image.ANTIALIAS)
        dest = BIRDIE_CACHE_PATH + os.path.basename(img_path) + ".jpg"
        img.save(dest)
        return dest
    except IOError:
        return None
