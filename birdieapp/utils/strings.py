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

import re


def text_ellipsed(text, chars=14):
    return (text[:chars] + '...').encode('utf-8') if len(text) > chars else text


def strip_html(txt):
    return re.sub(r'(<!--.*?-->|<[^>]*>)', '', txt)

def get_youtube_id(youtube_url):
    youtube_id = youtube_url.split("v=")[1]

    if "&" in youtube_id:
        youtube_id = youtube_id.split("&")[0]
    elif "#" in youtube_id:
        youtube_id = youtube_id.split("#")[0]
    elif "?" in youtube_id:
        youtube_id = youtube_id.split("?")[0]

    return youtube_id
